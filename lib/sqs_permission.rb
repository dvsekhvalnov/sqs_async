module SQS
  module Permissions
    All                     = "*"
    SendMessage             = "SendMessage"
    ReceiveMessage          = "ReceiveMessage"
    DeleteMessage           = "DeleteMessage"
    ChangeMessageVisibility = "ChangeMessageVisibility"
    GetQueueAttributes      = "GetQueueAttributes"

    def send_message
      SendMessage
    end

    def receive_message
      ReceiveMessage
    end

    def delete_message
      DeleteMessage
    end

    def change_message_visibility
      ChangeMessageVisibility
    end

    def get_queue_attributes
      GetQueueAttributes
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

