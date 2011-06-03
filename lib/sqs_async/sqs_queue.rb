require 'nokogiri'
require 'json'
require 'base64'

class SQSQueue
  attr_accessor :queue_url

  def self.parse(xml)
    doc = Nokogiri::XML(xml)
    queues = []
    doc.search("QueueUrl").each do |element|
      s = SQSQueue.new
      s.queue_url = URI.parse(element.text.strip)
      queues << s
    end
    queues
  end
end
