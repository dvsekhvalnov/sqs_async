require 'spec_helper'

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
      Timecop.freeze(Time.parse("2011-04-20T00:00:00 UTC")) do
        client.sign_params("http://edgecase.com/mysevice", {}).should == "AWSAccessKeyId=adsf&Expires=2011-04-20T00%3A30%3A00Z&SignatureMethod=HmacSHA256&SignatureVersion=2&Version=2012-11-05&Signature=0Iy50QIfQQAAb9JK59DGNgh8WdZwiwKK10RSiUefAAY%3D"
      end
    end

    it "generates valid signatures based on params" do
      req_desc = ["GET", 'foo', '/', "foo=bar&baz=fellini"].join("\n")
      client.generate_signature(req_desc).should == "WHmv1xv6iqPMw6kaw0sXVlqXfmoqkFpkKqBi2ONpAa4%3D"
    end
  end

  context "calls Amazon Endpoints asynchronously to" do

    it "change_message_visibility" do
      mock_obj = mock()
      mock_obj.expects(:call).once
      client.change_message_visibility(
        :queue => queue,
        :message => message,
        :visibility_timeout => Time.now.to_i + (30*60),
        :callbacks => { :success => mock_obj }
      )
      EM::HttpRequest.succeed(EM::MockResponse.new(xml_fixture(:change_message_visibility)))
    end

    it "set_queue_attributes" do
      mock_obj = mock()
      mock_obj.expects(:call).once
      client.set_queue_attributes(
          :queue => queue,
          :visibility_timeout => Time.now.to_i + (30*60),
          :callbacks => { :success => mock_obj }
      )
      EM::HttpRequest.succeed(EM::MockResponse.new(xml_fixture(:set_queue_attributes)))
    end

    context "putting a message on the queue" do
      it "send_message with SQSMessage object" do
        msg = SQSMessage.new
        msg.body = "foo"
        client.send_message(
          :queue => queue,
          :message => msg, 
          :callbacks => { 
            :success => lambda { |sqs_message_obj|
              sqs_message_obj.body.should == "foo"
              sqs_message_obj.md5_of_body.should_not be_nil
            }
          }
        )
        EM::HttpRequest.succeed(EM::MockResponse.new(xml_fixture(:send_message)))
      end

      it "send_message with message body" do
        client.send_message(
          :queue => queue,
          :message_body => "foo",
          :callbacks => {
            :success => lambda { |sqs_message_obj|
              sqs_message_obj.body.should == "foo"
              sqs_message_obj.md5_of_body.should_not be_nil
            }
          }
        )
        EM::HttpRequest.succeed(EM::MockResponse.new(xml_fixture(:send_message)))
      end
    end

    it "creates a queue" do
      client.create_queue(
        :queue_name => "testQueue",
        :callbacks => {
          :success => lambda{|queues|
            queues.length.should == 1
            queues.first.queue_url.to_s.should == "http://sqs.us-east-1.amazonaws.com/123456789012/testQueue"
          }
        }
      )
      EM::HttpRequest.succeed(EM::MockResponse.new(xml_fixture(:create_queue)))
    end

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

    context "permissions management" do
      let(:permissions) do
        leon = SQSPermission.new
        leon.aws_account_id = "a12digitcode"
        leon.permission = SQS::Permissions.all

        john = SQSPermission.new
        john.aws_account_id = "b12digitcode"
        john.permission = SQS::Permissions.send_message

        [leon, john]
      end

      let(:mock_closure) do
        mock_closure = mock()
        mock_closure.expects(:call).once
        mock_closure
      end

      it "adds permissions to a queue" do
        client.add_permission(
          :queue => queue,
          :permissions => permissions,
          :callbacks => { :success => mock_closure }
        )
        EM::HttpRequest.succeed(EM::MockResponse.new(xml_fixture(:add_permission)))
      end

      it "adds permissions to a queue" do
        client.remove_permission(
          :queue => queue,
          :permissions => permissions,
          :callbacks => { :success => mock_closure }
        )
        EM::HttpRequest.succeed(EM::MockResponse.new(xml_fixture(:remove_permission)))
      end
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
      mock_obj = mock()
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
