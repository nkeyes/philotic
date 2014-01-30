require 'philotic/connection'

module Philotic
  class Event
    include Philotic::Routable
    def self.inherited(sub)
      Philotic::EVENTBUS_HEADERS.each do |header|
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

    def initialize(options={})
      self.timestamp = Time.now.to_i
      self.philotic_firehose = true

      # dynamically insert any passed in options into both attr_routable
      # and attr_payload
      # result:  ability to arbitrarily send a easily routable hash
      # over into the bus
      options.each do |key, value|
        if self.respond_to?(:"#{key}=")
          send(:"#{key}=", value)
        elsif self.class == Philotic::Event
          self.class.attr_routable_readers.concat([key])
          self.class.attr_routable_writers.concat([:"#{key}="])

          self.class.attr_payload_readers.concat([key])
          self.class.attr_payload_writers.concat([:"#{key}="])
          setter = Proc.new do |v|
            instance_variable_set(:"@#{key}", v)
          end
          getter = Proc.new do
            instance_variable_get(:"@#{key}")
          end
          self.class.send :define_method, :"#{key}=", setter
          self.send(:"#{key}=", value)
          self.class.send :define_method, :"#{key}", getter
        end
      end

      self
    end
  end
end
