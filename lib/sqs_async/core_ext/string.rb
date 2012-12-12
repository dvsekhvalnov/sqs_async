require 'sqs_async/sqs_utilities'

class String

  include SQS::Utilities

  def underscore!
    underscore(self)
  end
end