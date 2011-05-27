require 'spec_helper'

describe "SQSMessage" do
  describe ".parse" do
    let(:messages) { SQSMessage.parse(xml_fixture(:receive_message)) }

    it "returns SQSMessage objects" do
      messages.length.should == 1
      messages.first.should be_a_kind_of(SQSMessage)
    end

    it "parses attributes" do
      message = messages.first
      message.body.should == "This is a test message"
      message.receipt_handle.should match /MbZj6wDWli.+?/im
      message.md5_of_body.should == "fafb00f5732ab283681e124bf8747ed1"
      message.message_id.should == "5fea7756-0ea4-451a-a703-a558b933e274"
    end
  end
end
