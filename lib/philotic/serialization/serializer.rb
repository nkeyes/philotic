module Philotic
  module Serialization
    module Serializer
      extend self

      def serializers
        @serializers ||= {}
      end

      def factory(serialization)
        serialization = serialization.to_s.downcase.to_sym
        @serializers[serialization]
      end

      def register(serializer)
        serializers[serializer.serialization] = serializer
      end

      # return the fully deserialized payload
      def load(payload, metadata)
        _transform(:load, payload, metadata)
      end

      def dump(payload, metadata)
        _transform(:dump, payload, metadata)
      end

      private
      def _transform(dump_or_load, payload, metadata)
        headers = metadata[:headers].deep_dup.deep_symbolize_keys

        serializations = headers[:philotic_serializations]

        serializations.reverse! if dump_or_load == :load

        serializations.reduce(payload.dup) do |transformed, serialization|
          serializer = factory serialization
          (serializer &&
            serializer.public_send(dump_or_load, transformed, metadata)) || transformed
        end
      end
    end
  end
end