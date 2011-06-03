require 'rake'
Gem::Specification.new do |s|
  s.name = 'sqs_async'
  s.version = '0.0.2'
  s.summary = 'Non-Blocking SQS library.'
  s.description = 'A simple library that leverages Event Machine to issue requests to the Amazon SQS service while blocking as little as possible'
  s.authors = "EdgeCase <contact@edgecase.com>", "John Andrews <john@edgecase.com>", "Leon Gersing <leon@edgecase.com>"
  s.email = "contact@edgecase.com"
  s.homepage = "https://github.com/edgecase/sqs_async"
  s.rubyforge_project = "sqs_async"

  s.add_dependency 'eventmachine', '~> 1.0.0.beta.3'
  s.add_dependency 'em-http-request', '~> 1.0.0.beta.4'
  s.add_dependency 'nokogiri'
  s.add_dependency 'json'
  s.add_dependency 'ruby-hmac'

  s.add_development_dependency 'rspec', '>= 2.6.0'
  s.add_development_dependency 'rspec-core'
  s.add_development_dependency 'rspec-expectations'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'timecop'

  s.files         = FileList.new('lib/*.rb')
  s.test_files    = FileList.new('spec/**/*')
  s.require_paths = ["lib"]
end

