require 'logger'
require 'philotic/logging/event'

module Philotic
  module Logging
    class Logger < ::Logger

      attr_writer :event_class
      attr_accessor :connection

      def event_class
        @event_class ||= Philotic::Logging::Event
      end

      def add(severity, message = nil, progname = nil)
        severity ||= UNKNOWN
        if @logdev.nil? or severity < @level
          return true
        end
        progname ||= @progname
        if message.nil?
          if block_given?
            message = yield
          else
            message  = progname
            progname = @progname
          end
        end
        @logdev.write(format_message(format_severity(severity), Time.now, progname, message))
        begin
          event = event_class.new(severity, message, progname)
          connection.publish event if connection
        rescue => e
          @logdev.write(format_message(format_severity(Logger::ERROR), Time.now, progname, e.message))
        end
        true
      end

      alias log add

    end
  end
end