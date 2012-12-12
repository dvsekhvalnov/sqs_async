require 'nokogiri'
require 'json'
require 'base64'
require 'ostruct'

class SQSMessage
  attr_accessor :body, :md5_of_body, :message_id, :receipt_handle, :attributes

  def self.parse(xml)
    doc = Nokogiri::XML(xml)
    messages = []
    doc.search("Message").each do |message_element|
      s = SQSMessage.new
      s.body = message_element.at("Body").text.strip
      s.md5_of_body = message_element.at("MD5OfBody").text.strip
      s.message_id = message_element.at("MessageId").text.strip
      s.receipt_handle = message_element.at("ReceiptHandle").text.strip
      s.attributes =Hash.new
      message_element.search("Attribute").each do |attribute|
        name = attribute.at("Name").text.strip.underscore!.to_sym
        value = attribute.at("Value").text.strip
        s.attributes[name]=value
      end

      post_process_known_attributes s

      messages << s
    end
    messages
  end

  def self.post_process_known_attributes(msg)
    msg.attributes[:approximate_receive_count]=msg.attributes[:approximate_receive_count].to_i if (msg.attributes.has_key? :approximate_receive_count)
    msg.attributes[:approximate_first_receive_timestamp]=Time.at(msg.attributes[:approximate_first_receive_timestamp].to_i/1000) if (msg.attributes.has_key? :approximate_first_receive_timestamp)
    msg.attributes[:sent_timestamp]=Time.at(msg.attributes[:sent_timestamp].to_i/1000) if (msg.attributes.has_key? :sent_timestamp)
  end
end
