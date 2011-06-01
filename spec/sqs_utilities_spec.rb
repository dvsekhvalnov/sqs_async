require 'spec_helper'

describe "SQS::Utilities" do
  include SQS::Utilities # i <3 ruby. :)

  it "amazonizes the keys of a hash" do
    hash = {:queue_name =>"foo", :default_visibility_timeout => 30}
    hash.amazonize_keys!
    hash["QueueName"].should == "foo"
  end
end
