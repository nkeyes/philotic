require 'active_support/all'
require 'active_record'

module Philotic
  module Routable
    def self.included(base)
      base.send :include, ActiveRecord::Validations
      base.send :include, ActiveRecord::Callbacks
      base.validates :philotic_firehose, :philotic_product, :philotic_component, :philotic_event_type, presence: true

      base.extend ClassMethods
    end

    def payload
      attribute_hash = {}
      self.class.attr_payload_readers.each do |attr|
        attr                 = attr.to_sym
        attribute_hash[attr] = send(attr)
      end
      attribute_hash
    end

    def headers
      attribute_hash = {}
      self.class.attr_routable_readers.each do |attr|
        attr                 = attr.to_sym
        attribute_hash[attr] = send(attr)
      end
      attribute_hash
    end

    def attributes
      attribute_hash = {}
      (self.class.attr_payload_readers + self.class.attr_routable_readers).each do |attr|
        attr                 = attr.to_sym
        attribute_hash[attr] = send(attr)
      end
      attribute_hash
    end

    def message_metadata
      @message_metadata ||= {}
    end

    def message_metadata= options
      @message_metadata ||= {}
      @message_metadata.merge! options
    end

    def publish &block
      Philotic::Publisher.publish(self, &block)
    end

    module ClassMethods
      def attr_payload_reader *names
        attr_payload_readers.concat(names)
        attr_reader(*names)
      end

      def attr_payload_readers
        @attr_payload_readers ||= []
      end

      def attr_payload_writer *names
        attr_payload_writers.concat names
        attr_writer(*names)
      end

      def attr_payload_writers
        @attr_payload_writers ||= []
      end

      def attr_payload *names
        names -= attr_payload_readers
        attr_payload_readers.concat(names)
        attr_payload_writers.concat(names)
        attr_accessor(*names)
      end

      def attr_routable_reader *names
        attr_routable_reader.concat(names)
        attr_reader(*names)
      end

      def attr_routable_readers
        @attr_routable_readers ||= []
      end

      def attr_routable_writers
        @attr_routable_writers ||= []
      end

      def attr_routable_writer *names
        attr_routable_writers.concat names
        attr_writer(*names)
      end

      def attr_routable *names
        names -= attr_routable_readers
        attr_routable_readers.concat(names)
        attr_routable_writers.concat(names)
        attr_accessor(*names)
      end

      def publish(*args, &block)
        self.new(*args).publish(&block)
      end
    end
  end
end
