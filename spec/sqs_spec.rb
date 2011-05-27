require 'spec_helper'
require 'sqs'

class MySQSClient
  include SQS
  def initialize
    self.aws_key = 'adsf'
    self.aws_secret = 'adsffasdf'
  end
end

describe "SQS" do
  let(:client)  { MySQSClient.new }
  let(:queue)   { SQSQueue.new.tap { |q| q.queue_url = URI.parse("http://sqs.us-east-1.amazonaws.com/123456789012/testQueue") } }
  let(:message) { SQSMessage.new.tap {|msg| msg.receipt_handle = "foo" } }

  # we are testing private members because the
  # interaction with Amazon is stubbed. Therefore
  # we want to ensure that these perform as expected
  # even though they would normally be encapsulated by
  # calls to amazon.
  #
  # Leon and John 5-31-11
  context "Private member testing" do

    before(:all) do
      MySQSClient.send :public, :sign_params
      MySQSClient.send :public, :generate_signature
    end

    after(:all) do
      MySQSClient.send :private, :sign_params
      MySQSClient.send :private, :generate_signature
    end

    it "signs requests prior to sending" do
      Timecop.freeze(Time.parse("2011-04-20T00:00:00")) do
        client.sign_params("http://edgecase.com/mysevice", {}).should == "AWSAccessKeyId=adsf&Expires=2011-04-20T04%3A30%3A00Z&SignatureMethod=HmacSHA256&SignatureVersion=2&Version=2009-02-01&Signature=oKFwSahHQIMKiSOabVZqwcZEFowOdqyyj2gamyjJ3oU%3D"
      end
    end

    it "generates valid signatures based on params" do
      req_desc = ["GET", 'foo', '/', "foo=bar&baz=fellini"].join("\n")
      client.generate_signature(req_desc).should == "WHmv1xv6iqPMw6kaw0sXVlqXfmoqkFpkKqBi2ONpAa4%3D"
    end
  end

  context "calls Amazon Endpoints asynchronously to" do
    it "list available queues" do
      client.list_queues(
        :callbacks => {
          :success => lambda{|queues|
            queues.length.should == 1
            queues.first.queue_url.to_s.should == "http://sqs.us-east-1.amazonaws.com/123456789012/testQueue"
          }
        }
      )
      EM::HttpRequest.succeed(EM::MockResponse.new(xml_fixture(:list_queues)))
    end

    it "pull a message from the queue" do
      queue.queue_url = URI.parse("http://sqs.us-east-1.amazonaws.com/123456789012/testQueue")
      client.receive_message(
        :queue => queue,
        :callbacks => {
          :success => lambda{|messages|
            messages.kind_of?(Enumerable).should == true
            messages.length.should == 1
            messages.first.kind_of?(SQSMessage).should == true
          }
        }
      )

      EM::HttpRequest.succeed(EM::MockResponse.new(xml_fixture(:receive_message)))
    end

    it "delete a message from the queue" do
      mock_obj = mock();
      mock_obj.expects(:call).once
      client.delete_message(
        :queue => queue,
        :message => message,
        :callbacks => { :success => mock_obj }
      )

      EM::HttpRequest.succeed(EM::MockResponse.new(xml_fixture(:delete_message)))
    end

    it "gets the queue's attributes" do
      client.get_queue_attributes(
        :queue => queue,
        :callbacks => {
          :success => lambda{|attr_obj|
            attr_obj.kind_of?(SQSAttributes).should == true
          }
        }
      )

      EM::HttpRequest.succeed(EM::MockResponse.new(xml_fixture(:queue_attributes)))
    end
  end
  context "error result" do
    let(:fail_mock) do
      fail_mock = mock
      fail_mock.expects(:call).once
      fail_mock
    end

    let(:error_result) do
      EM::MockResponse.new(xml_fixture(:error_response))
    end

    it "list_queues failure" do
      client.list_queues(
        :callbacks => {
          :failure => fail_mock
        }
      )
      EM::HttpRequest.succeed(error_result)
    end

    it "list_queues failure on misc http error not related to amazon" do
      client.list_queues(
        :callbacks => {
          :failure => fail_mock
        }
      )
      EM::HttpRequest.error(error_result)
    end

    it "receive_message failure" do
      client.receive_message(
        :queue => queue,
        :callbacks => {
          :failure => fail_mock
        }
      )
      EM::HttpRequest.succeed(error_result)
    end

    it "delete_message failure" do
      client.delete_message(
        :queue => queue,
        :message => message,
        :callbacks => {
          :failure => fail_mock
        }
      )
      EM::HttpRequest.succeed(error_result)
    end
  end
end
