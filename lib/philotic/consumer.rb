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

    def before_acknowledge(message)
      # no op
    end

    def after_acknowledge(message)
      # no op
    end

    def before_requeue(message)
      # no op
    end

    def after_requeue(message)
      # no op
    end

    def before_reject(message)
      # no op
    end

    def after_reject(message)
      # no op
    end

    def acknowledge_message(message)
      _safe_hook(:before_acknowledge, message)
      acknowledge(message)
      _safe_hook(:after_acknowledge, message)
    end

    def requeue_message(message)
      _safe_hook(:before_requeue, message)
      reject(message, true)
      _safe_hook(:after_requeue, message)

    end

    def reject_message(message)
      _safe_hook(:before_reject, message)
      reject(message, false)
      _safe_hook(:before_reject, message)

    end

    private

    def _safe_hook(hook, message)
      begin
        send(hook, message)
      rescue => e
        logger.error {}
      end

    end

    def _consume(message)
      if self.class.auto_acknowledge?
        _auto_ack_consume(message)
      else
        consume(message)
      end
    end

    def _auto_ack_consume(message)
      begin
        consume(message)
        acknowledge_message(message)
      rescue => e
        if self.class.requeueable_errors.include? e.class
          requeue_message(message)
        else
          reject_message(message)
        end
      end
    end
  end
end