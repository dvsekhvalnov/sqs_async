ENV["BUBBLE_ENV"] = "test"
$:.unshift(File.dirname(__FILE__)+"/lib/")

require 'bundler/setup'
require 'rspec'
require 'timecop'
require 'em-http-request'

require 'sqs_async'

RSpec.configure do |config|
  config.mock_framework = :mocha

  def xml_fixture(name)
    File.read(File.dirname(__FILE__)+"/fixtures/#{name}.xml")
  end
end

module EventMachine
  class MockHttpRequest
    def initialize *args
      @callbacks = []
      @errbacks = []
    end

    def get *args
      self
    end

    def post *args
      self
    end

    def callback &block
      @callbacks << block
    end

    def errback &block
      @errbacks << block
    end

    def succeed(response)
      @callbacks.each {|c| c.call(response)}
      reset
    end

    def error(response)
      @errbacks.each {|c| c.call(response)}
      reset
    end

    def reset
      @callbacks = []
      @errbacks = []
    end
  end

  class HttpRequest
    def self.new *args
      request = MockHttpRequest.new
      connection_instances << request
      request
    end

    def self.connection_instances
      @connection_instances ||= []
    end

    def self.succeed(response)
      connection_instances.each do |conn|
        conn.succeed(response)
      end
    end

    def self.error(response)
      connection_instances.each do |conn|
        conn.error(response)
      end
    end
  end

  class MockResponse
    def initialize(body)
      @body = body
    end

    def response
      @body
    end
    alias :error :response
  end
end
