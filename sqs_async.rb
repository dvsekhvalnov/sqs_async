$:.unshift(File.dirname(__FILE__))
%w{ lib lib/core_ext }.each do |d|
  $:.unshift(File.dirname(__FILE__)+"/#{d}/")
end

# Core extensions and global mixins
require 'core_ext/hash'
require 'sqs_utilities'

# App classes and modules
require 'sqs_queue'
require 'sqs_message'
require 'sqs_attributes'
require 'sqs_permission'
require 'sqs_send_message_response'

# main app module
require 'sqs'
