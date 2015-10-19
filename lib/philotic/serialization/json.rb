require 'multi_json'
require 'oj'

require 'philotic/serialization/serializer'

module Philotic
  module Serialization
    module Json
      extend self

      def content_type
        'application/json'
      end

      def serialization
        :json
      end

      def dump(payload, metadata)
        MultiJson.dump payload
      end

      def load(payload, metadata)
        MultiJson.load payload
      end
    end
  end
end
Philotic::Serialization::Serializer.register Philotic::Serialization::Json