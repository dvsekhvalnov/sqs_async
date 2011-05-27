require 'spec_helper'

describe "SQSAttributes" do
  describe ".parse" do
    let(:attributes_obj) { SQSAttributes.parse(xml_fixture(:queue_attributes)) }

    it "returns SQSAttributes objects" do
      attributes_obj.should be_a_kind_of(SQSAttributes)
    end

    it "parses attributes" do
      attributes_obj.approximate_number_of_messages.should == "0"
      attributes_obj.approximate_number_of_messages_not_visible.should == "0"
      attributes_obj.visibility_timeout.should == "30"
      attributes_obj.create_timestamp.should == nil
      attributes_obj.last_modified_timestamp.should == "1286771522"
      attributes_obj.policy.should == nil
      attributes_obj.maximum_message_size.should == "8192"
      attributes_obj.message_retention_period.should == "345600"
      attributes_obj.queue_arn.should == "arn:aws:sqs:us-east-1:123456789012:qfoo"
    end
  end
end
