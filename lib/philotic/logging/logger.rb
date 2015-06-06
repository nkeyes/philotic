require 'logger'
require 'philotic/logging/message'

module Philotic
  module Logging
    class Logger < ::Logger

      attr_writer :message_class
      attr_accessor :connection

      def message_class
        @message_class ||= Philotic::Logging::Message
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
          message = message_class.new(severity, message, progname)
          connection.publish message if connection
        rescue => e
          @logdev.write(format_message(format_severity(Logger::ERROR), Time.now, progname, e.message))
        end
        true
      end

      alias log add

    end
  end
end