require 'spec_helper'
require 'sqs_message'

describe "SQSQueue" do
  context ".parse" do
    let(:queues) { SQSQueue.parse(xml_fixture(:list_queues)) }

    it "returns SQSQueue objects" do
      queues.length.should == 1
      queues.first.should be_a_kind_of(SQSQueue)
    end

    it "parses attributes" do
      queue = queues.first
      queue.queue_url.should == URI.parse("http://sqs.us-east-1.amazonaws.com/123456789012/testQueue")
    end
  end
end
