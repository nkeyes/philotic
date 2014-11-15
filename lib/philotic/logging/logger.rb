require 'logger'
require 'philotic/logging/event'

module Philotic
  module Logging
    class Logger < ::Logger

      attr_writer :event_class

      def event_class
        @event_class ||= Philotic::Logging::Event
      end

      def add(severity, message = nil, progname = nil, &block)
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
        @logdev.write(
            format_message(format_severity(severity), Time.now, progname, message))
        event_class.publish(severity, message, progname)

        true
      end

      alias log add

    end
  end
end