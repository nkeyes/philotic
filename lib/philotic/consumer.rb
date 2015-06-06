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

      def ack_messages
        @ack_messages = true
      end

      def exclusive
        @exclusive = true
      end

      def ack_messages?
        !!@ack_messages
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
          manual_ack: ack_messages?,
          exclusive:  exclusive?,
        }
      end
    end

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
      if self.class.ack_messages?
        begin
          consume(message)
        rescue => e

          if self.class.requeueable_errors.include? e.class
            reject(message, true)
            return
          elsif self.class.rejectable_errors.include? e.class
            reject(message, false)
            return
          else
            raise e
          end
        end
        acknowledge(message)
      else
        consume(message)
      end
    end
  end
end