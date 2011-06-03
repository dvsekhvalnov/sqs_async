module SQS
  module Permissions
    def self.all
      "*"
    end

    def self.send_message
      "SendMessage"
    end

    def self.receive_message
      "ReceiveMessage"
    end

    def self.delete_message
      "DeleteMessage"
    end

    def self.change_message_visibility
      "ChangeMessageVisibility"
    end

    def self.get_queue_attributes
      "GetQueueAttributes"
    end
  end
end

class SQSPermission
  include SQS::Permissions
  attr_accessor :aws_account_id, :permission

  def to_params(ordinal=1)
    {
      "Label"          => "#{aws_account_id}-#{permission.to_s}",
      "AWSAccountId.#{ordinal}" => aws_account_id,
      "ActionName.#{ordinal}"   => permission.to_s
    }
  end
end

