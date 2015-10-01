require 'multi_json'
require 'oj'

module Philotic
  module Serializer
    module Json
      extend self
      extend Forwardable

      def self.content_type
        'application/json'
      end

      def_delegators MultiJson, :dump, :load
    end
  end
end