%w{ ./ lib }.each do |d|
  $:.unshift(File.dirname(__FILE__)+"/#{d}/")
end

require 'sqs'
require 'sqs_utilities'
require 'sqs_attributes'
require 'sqs_message'
require 'sqs_queue'
require 'sqs_permission'
require 'sqs_send_message_response'

require 'core_ext/hash'
