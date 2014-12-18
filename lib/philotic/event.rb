require 'philotic/constants'
require 'philotic/routable'
require 'philotic/singleton'

module Philotic
  class Event
    include Philotic::Routable

    attr_accessor :connection

    def initialize(routables={}, payloads={}, connection=nil)
      self.timestamp         = Time.now.to_i
      self.philotic_firehose = true
      self.connection = connection

      # dynamically insert any passed in routables into both attr_routable
      # and attr_payload
      # result:  ability to arbitrarily send a easily routable hash
      # over into the bus
      _set_routables_or_payloads(:routable, routables)
      _set_routables_or_payloads(:payload, payloads)
    end

    def self.inherited(sub)
      Philotic::PHILOTIC_HEADERS.each do |header|
        sub.attr_routable header
      end
      self.attr_routable_readers.dup.each do |routable|
        sub.attr_routable routable
      end

      self.attr_payload_readers.dup.each do |payload|
        sub.attr_payload payload
      end
    end

    self.inherited(self)

    Philotic::MESSAGE_OPTIONS.each do |message_option|
      attr_reader message_option
      define_method :"#{message_option}=" do |val|
        instance_variable_set(:"@#{message_option}", val)
        self.message_metadata[message_option] = val
      end
    end

    def connection
      @connection ||= Philotic.connection
    end

    def publish
      connection.publish self
    end

    def self.publish(*args)
      self.new(*args).publish
    end

    private

    def _set_routables_or_payloads(type, attrs)
      attrs.each do |key, value|
        if self.respond_to?(:"#{key}=")
          send(:"#{key}=", value)
        elsif self.class == Philotic::Event
          _set_event_attribute(type, key, value)
        end
      end
    end

    def _set_event_attribute(type, key, value)
      _set_event_attribute_setter(key, type, value)
      _set_event_attribute_getter(key, type)
    end

    def _set_event_attribute_getter(key, type)
      self.class.send("attr_#{type}_readers").concat([key])
      getter = lambda do
        instance_variable_get(:"@#{key}")
      end
      self.class.send :define_method, :"#{key}", getter
    end

    def _set_event_attribute_setter(key, type, value)
      self.class.send("attr_#{type}_writers").concat([:"#{key}="])
      setter = lambda do |v|
        instance_variable_set(:"@#{key}", v)
      end
      self.class.send :define_method, :"#{key}=", setter
      self.send(:"#{key}=", value)
    end
  end
end
