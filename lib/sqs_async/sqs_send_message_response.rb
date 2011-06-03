require 'nokogiri'
require 'json'
require 'base64'
require 'ostruct'

class SQSSendMessageResponse
  attr_accessor :body, :md5_of_body, :message_id, :receipt_handle

  def self.parse(original_body, xml)
    doc = Nokogiri::XML(xml)
    message = SQSMessage.new
    doc.search("SendMessageResult").each do |message_element|
      message.body = original_body || ""
      message.md5_of_body = message_element.at("MD5OfMessageBody").text.strip
      message.message_id = message_element.at("MessageId").text.strip
    end
    message
  end
end
