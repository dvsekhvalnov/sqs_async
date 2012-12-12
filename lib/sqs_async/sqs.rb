require 'uri'
require 'cgi'
require 'hmac'
require 'hmac-sha2'
require 'base64'
require 'net/http'
require 'time'
require 'nokogiri'
require 'json'
require 'eventmachine'
require 'em-http-request'
require 'logger'
require 'sqs_async/sqs_utilities'
require 'sqs_async/sqs_message'
require 'sqs_async/sqs_attributes'
require 'sqs_async/sqs_queue'
require 'sqs_async/core_ext/hash'

module SQS
  include SQS::Utilities
  attr_accessor :aws_key, :aws_secret, :regions, :default_parameters, :post_options

  def change_message_visibility(options={})
    raise "no Message specified" unless options[:message]
    raise "no new visibility_timeout specified" unless options[:visibility_timeout]
    options.merge!( :receipt_handle => options.delete(:message).receipt_handle,
                    :visibility_timeout => options.delete(:visibility_timeout).to_i)
    call_amazon(options)
  end

  def set_queue_attributes(options={})
    raise "no target queue specified" unless options[:queue]
    %w[ :visibility_timeout :policy :maximum_message_size :message_retention_period ].each do |attr_type|
      if options[attr_type]
        val = options.delete(attr_type)
        options.merge! "Attribute.Name" => camelize(attr_type), "Attribute.Value" => val
      end
    end

    call_amazon(options)
  end

  def send_message(options={})
    raise "no object(:message) or string(:message_body) specified" unless (options[:message] || options[:message_body])
    options.merge!( :message_body => options.delete(:message).body ) if options[:message]
    body = options[:message_body]

    call_amazon(options){ |req| SQSSendMessageResponse.parse(body, req.response) }
  end

  def add_permission(options={})
    raise "no target queue specified" unless options[:queue]
    raise "no permissions objects specified" unless options[:permissions]

    [options[:permissions]].flatten.each_with_index do |perm, index|
      ordinal = index+1
      options.merge!(perm.to_params(ordinal)) # last label wins.
    end

    options.delete(:permissions)

    call_amazon(options)
  end

  def remove_permission(options={})
    raise "no target queue specified" unless options[:queue]
    raise "no permissions objects specified" unless options[:permissions]

    [options[:permissions]].flatten.each_with_index do |perm, index|
      ordinal = index+1
      options.merge!(perm.to_params(ordinal)) # last label wins.
    end

    options.delete(:permissions)

    call_amazon(options)
  end

  def list_queues(options={})
    prefix = options.delete(:prefix)
    match = options.delete(:match)

    options.merge!( :queue_name_prefix => encode(prefix) ) if prefix

    call_amazon(options) do |req|
      queues = SQSQueue.parse(req.response)
      queues.select!{|q| q.queue_url.path.match(match) } if match
      queues
    end
  end

  def receive_message(options={})
    raise "no target queue specified" unless options[:queue]
    options = { :max_number_of_messages => 10 }.merge(options)
    call_amazon(options){ |req| SQSMessage.parse(req.response) }
  end

  def delete_message(options={})
    raise "no Message specified" unless options[:message]
    options.merge!(:receipt_handle => options.delete(:message).receipt_handle)
    call_amazon(options)
  end

  def get_queue_attributes(options={})
    raise "no target queue specified" unless options[:queue]
    options = {:attribute_name => "All" }.merge(options)
    call_amazon(options){ |req| SQSAttributes.parse(req.response) }
  end

  def delete_queue(options={})
    raise "no target queue specified" unless options[:queue]
    call_amazon(options)
  end

  def create_queue(options={})
    raise "no queue name specified" unless options[:queue_name]
    options[:default_visibility_timeout] = 30 unless options[:default_visibility_timeout]
    call_amazon(options){ |req| SQSQueue.parse(req.response) }
  end

  private

    def call_amazon(options)
      endpoint = (options[:queue] != nil) ? options.delete(:queue).queue_url : "http://" << ( options.delete(:host) || region_host(:us_east) )
      callbacks = options.delete(:callbacks) || {:success=>nil, :failure =>nil }

      if( who_called_us = caller(0)[1] )
        options = {:action => action_from_caller(who_called_us)}.merge(options)
      end

      options.amazonize_keys!

      params = sign_params( endpoint, options )
      req = EM::HttpRequest.new("#{endpoint}?#{params}").get
      req.callback do |req_ref|
        if(req_ref.response.to_s.match(/<ErrorResponse/i))
           on_failure(req_ref, callbacks)
        else
          result = req_ref
          result = yield req_ref if block_given?
          callbacks[:success].call(result) if callbacks[:success]
        end
      end
      req.errback { |req_ref| on_failure(req_ref, callbacks) }
    end

    def on_failure(req, callbacks)
      result = (req.error != nil) ? req.error : req.response
      log result
      callbacks[:failure].call(result) if callbacks[:failure]
    end

    def sign_params(uri, opts)
      uri = URI.parse(uri) if uri.kind_of? String
      opts = default_parameters.merge(opts)

      sorted_params = opts.sort {|x,y| x[0] <=> y[0]}
      encoded_params = sorted_params.collect do |p|
        encode(p[0].to_s) << "=" << encode(p[1].to_s)
      end
      params_string = encoded_params.join("&")

      req_desc = ["GET", uri.host.downcase, uri.request_uri, params_string].join("\n")
      params_string << "&Signature=" << generate_signature(req_desc)
    end

    def generate_signature(request_description)
      hmac = HMAC::SHA256.new(aws_secret)
      hmac.update(request_description)
      encode(Base64.encode64(hmac.digest).chomp)
    end

    def encoding_exclusions
      /[^\w\d\-_\.~]/
    end

    def encode(val)
      URI.encode(val, encoding_exclusions)
    end

    def region_host(key)
      regions[key][:uri]
    end

    def regions
      @regions ||= REGIONS
      @regions
    end

    def default_parameters
      @default_parameters ||= PARAMETERS.merge("AWSAccessKeyId" => aws_key)
      @default_parameters.merge("Expires" => (Time.now+(60*30)).utc.iso8601)
    end

    def post_options
      @post_options ||= POSTOPTIONS
      @post_options
    end

    def logger
      return @logger if @logger

      @logger = Logger.new @log_path || "./sqs_async.log"
      @logger.level = @log_level || Logger::WARN
      @logger
    end

    def log(msg)
      log_msg = ["SERVICE ERROR"]
      log_msg << caller[0..7].join("\n\t")
      log_msg << "-".ljust(80, "-")
      log_msg << msg
      log_msg << "-".ljust(80, "-")
      logger.error(log_msg.join("\n"))
    end

    REGIONS = {
      :us_east => { :name => "US-East (Northern Virginia) Region", :uri  => "sqs.us-east-1.amazonaws.com"},
      :us_west => { :name => "US-West (Northern California) Region", :uri  => "sqs.us-west-1.amazonaws.com"},
      :eu => { :name => "EU (Ireland) Region", :uri  => "sqs.eu-west-1.amazonaws.com"},
      :asia_singapore => { :name => "Asia Pacific (Singapore) Region", :uri  => "sqs.ap-southeast-1.amazonaws.com"},
      :asia_tokyo => { :name => "Asia Pacific (Tokyo) Region", :uri  => "sqs.ap-northeast-1.amazonaws.com"}
    }


    PARAMETERS = {
      "Version" => "2012-11-05",
      "SignatureVersion"=>"2",
      "SignatureMethod"=>"HmacSHA256",
    }

    POSTOPTIONS = {
      "Content-Type" => "application/x-www-form-urlencoded"
    }
end
