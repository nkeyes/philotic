require 'philotic/subscriber'

module Philotic
  class Consumer < Philotic::Subscriber

    def self.subscribe_to(subscription)
      @subscription = subscription
    end

    def self.subscribe
      new(Philotic.connection).tap do |instance|
        instance.subscribe
      end
    end

    def self.subscription
      @subscription
    end

    def subscribe
      super(self.class.subscription) do |event, metadata|
        consume(event)
      end
      Philotic.endure
      self
    end

    def consume(event)
      raise NotImplementedError
    end
  end
end