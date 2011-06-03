# These mixins are lovingly taken from active support.
# License information is available online at rubyonrails.org

module SQS
  module Utilities

    def action_from_caller(first_element_in_caller)
      camelize(first_element_in_caller.scan(/\`(\w+)\'/).flatten.first)
    end

    def camelize(str)
      str.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    end

    def underscore(camel_cased_word)
      word = camel_cased_word.to_s.dup
      word.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
      word.tr!("-", "_")
      word.downcase!
      word
    end

  end
end

