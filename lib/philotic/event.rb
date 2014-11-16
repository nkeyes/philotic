require 'philotic/constants'
require 'philotic/connection'
require 'philotic/routable'

module Philotic
  class Event
    include Philotic::Routable

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
      Philotic::Connection.instance
    end

    def set_routables_or_payloads(type, attrs)
      attrs.each do |key, value|
        if self.respond_to?(:"#{key}=")
          send(:"#{key}=", value)
        elsif self.class == Philotic::Event
          set_event_attribute(type, key, value)
        end
      end
    end

    def set_event_attribute(type, key, value)
      set_event_attribute_setter(key, type, value)
      set_event_attribute_getter(key, type)
    end

    def set_event_attribute_getter(key, type)
      self.class.send("attr_#{type}_readers").concat([key])
      getter = lambda do
        instance_variable_get(:"@#{key}")
      end
      self.class.send :define_method, :"#{key}", getter
    end

    def set_event_attribute_setter(key, type, value)
      self.class.send("attr_#{type}_writers").concat([:"#{key}="])
      setter = lambda do |v|
        instance_variable_set(:"@#{key}", v)
      end
      self.class.send :define_method, :"#{key}=", setter
      self.send(:"#{key}=", value)
    end

    def initialize(routables={}, payloads=nil)
      payloads               ||= {}
      self.timestamp         = Time.now.to_i
      self.philotic_firehose = true

      # dynamically insert any passed in routables into both attr_routable
      # and attr_payload
      # result:  ability to arbitrarily send a easily routable hash
      # over into the bus
      set_routables_or_payloads(:routable, routables)
      set_routables_or_payloads(:payload, payloads)
      self
    end
  end
end
