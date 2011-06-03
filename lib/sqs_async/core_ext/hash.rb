require 'sqs_async/sqs_utilities'

class Hash
  include SQS::Utilities

  def amazonize_keys!
    keys = self.keys
    keys.each do |k|
      self[camelize(k.to_s)] = self[k]
      self.delete(k)
    end
  end
end
