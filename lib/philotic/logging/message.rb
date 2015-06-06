require 'philotic/message'

module Philotic
  module Logging
    class Message < Philotic::Message
      attr_routable :severity, :progname
      attr_payload :message

      def initialize(severity, message = nil, progname = nil)
        super({})
        self.severity = severity
        self.message  = message
        self.progname = progname

      end
    end
  end
end