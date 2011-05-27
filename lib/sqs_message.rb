require 'nokogiri'
require 'json'
require 'base64'
require 'ostruct'

class SQSMessage
  attr_accessor :body, :md5_of_body, :message_id, :receipt_handle

  def self.parse(xml)
    doc = Nokogiri::XML(xml)
    messages = []
    doc.search("Message").each do |message_element|
      s = SQSMessage.new
      s.body = message_element.at("Body").text.strip
      s.md5_of_body = message_element.at("MD5OfBody").text.strip
      s.message_id = message_element.at("MessageId").text.strip
      s.receipt_handle = message_element.at("ReceiptHandle").text.strip
      messages << s
    end
    messages
  end
end
