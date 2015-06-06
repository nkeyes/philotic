require 'philotic/singleton'
require 'philotic/subscriber'

module Philotic
  class Consumer < Philotic::Subscriber

    class << self
      def subscribe_to(subscription)
        @subscription = subscription
      end

      def subscription
        @subscription
      end

      def manually_acknowledge
        @manually_acknowledge = true
      end

      def manually_acknowledge?
        !!@manually_acknowledge
      end

      def auto_acknowledge
        @auto_acknowledge = true
      end

      def auto_acknowledge?
        !!@auto_acknowledge
      end

      def exclusive
        @exclusive = true
      end

      def exclusive?
        !!@exclusive
      end

      def requeueable_errors(*errors)
        @requeueable_errors ||= Set.new
        @requeueable_errors.merge errors
        @requeueable_errors
      end

      def rejectable_errors(*errors)
        @rejectable_errors ||= Set.new
        @rejectable_errors.merge errors
        @rejectable_errors
      end

      def subscribe
        new(Philotic.connection).tap do |instance|
          instance.subscribe
        end
      end

      def subscription_options
        {
          manual_ack: auto_acknowledge? || manually_acknowledge?,
          exclusive:  exclusive?,
        }
      end
    end # end class methods

    def subscribe
      super(self.class.subscription, self.class.subscription_options) do |message|
        _consume(message)
      end
    end

    def consume(message)
      raise NotImplementedError
    end

    private

    def _consume(message)
      if self.class.auto_acknowledge?
        begin
          consume(message)
          acknowledge(message)
        rescue => e
          if self.class.requeueable_errors.include? e.class
            reject(message, true)
          elsif self.class.rejectable_errors.include? e.class
            reject(message, false)
          else
            raise e
          end
        end
      else
        consume(message)
      end
    end
  end
end