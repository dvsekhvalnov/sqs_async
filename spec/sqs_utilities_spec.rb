require 'spec_helper'

describe "SQS::Utilities" do
  include SQS::Utilities # i <3 ruby. :)

  it "amazonizes the keys of a hash" do
    hash = {:queue_name =>"foo", :default_visibility_timeout => 30}
    hash.amazonize_keys!
    hash["QueueName"].should == "foo"
  end

  it "infers an amazonized action from the calling context" do
    def this_would_be_the_same_as_an_action_name
      sample_target
    end

    def sample_target
      action_from_caller(caller(0)[1]).should == "ThisWouldBeTheSameAsAnActionName"
    end

    this_would_be_the_same_as_an_action_name
  end
end
