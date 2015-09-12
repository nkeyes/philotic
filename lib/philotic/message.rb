require 'philotic/constants'
require 'philotic/singleton'

module Philotic
  class Message
    NotInstantiableError = Class.new(RuntimeError)

    attr_accessor :connection, :publish_error, :delivery_info
    attr_writer :published

    class << self
      def attr_routable_accessors
        @attr_routable_accessors ||= Set.new
      end

      def attr_payload_accessors
        @attr_payload_accessors ||= Set.new
      end

      def attr_routable(*names)
        attr_routable_accessors.merge(names)
        attr_accessor(*names)
      end

      def attr_payload(*names)
        attr_payload_accessors.merge(names)
        attr_accessor(*names)
      end
    end

    def initialize(routables={}, payloads={}, connection=nil)
      raise NotInstantiableError if self.class == Philotic::Message
      self.timestamp         = Time.now.to_i
      self.philotic_firehose = true
      self.connection        = connection

      # dynamically insert any passed in routables into both attr_routable
      # and attr_payload
      # result:  ability to arbitrarily send a easily routable hash
      # over into the bus
      _set_routables_or_payloads(:routable, routables)
      _set_routables_or_payloads(:payload, payloads)

      @published = false
    end

    def self.inherited(sub_class)
      sub_class.attr_routable(*Philotic::PHILOTIC_HEADERS)
      sub_class.attr_routable(*self.attr_routable_accessors.dup)
      sub_class.attr_payload(*self.attr_payload_accessors.dup)
    end

    self.inherited(self)

    Philotic::MESSAGE_OPTIONS.each do |message_option|
      attr_reader message_option
      define_method :"#{message_option}=" do |val|
        instance_variable_set(:"@#{message_option}", val)
        self.metadata[message_option] = val
      end
    end

    def connection
      @connection ||= Philotic.connection
    end

    def published?
      !!@published
    end

    def publish
      connection.publish self
    end

    def self.publish(*args)
      message_class = self == Philotic::Message ? Class.new(self) : self
      message_class.new(*args).publish
    end

    def delivery_tag
      delivery_info.try(:delivery_tag)
    end

    def payload
      _payload_or_headers(:payload)
    end

    def headers
      _payload_or_headers(:routable)
    end

    def attributes
      payload.merge headers
    end

    def metadata
      @metadata ||= {}
    end

    def metadata=(options)
      @metadata ||= {}
      @metadata.merge! options
    end

    private

    def _is_anonymous_message?
      self.is_a?(Philotic::Message) && self.class.name.nil?
    end

    def _payload_or_headers(payload_or_headers)
      attribute_hash = {}
      self.class.send("attr_#{payload_or_headers}_accessors").each do |attr|
        attr                 = attr.to_sym
        attribute_hash[attr] = send(attr)
      end
      attribute_hash
    end

    def _set_routables_or_payloads(type, attrs)
      attrs.each do |key, value|
        if self.respond_to?(:"#{key}=")
          send(:"#{key}=", value)
        elsif _is_anonymous_message?
          _set_message_attribute(type, key, value)
        end
      end
    end

    def _set_message_attribute(type, key, value)
      self.class.send("attr_#{type}_accessors").merge([key])
      _set_message_attribute_accessor(key, value)
    end

    def _set_message_attribute_accessor(attr, value)
      _set_message_attribute_getter(attr)
      _set_message_attribute_setter(attr)
      self.send(:"#{attr}=", value)
    end

    def _set_message_attribute_getter(attr)
      self.define_singleton_method :"#{attr}" do
        instance_variable_get(:"@#{attr}")
      end
    end

    def _set_message_attribute_setter(attr)
      self.define_singleton_method :"#{attr}=" do |v|
        instance_variable_set(:"@#{attr}", v)
      end
    end
  end
end
