module Philotic
  class Subscriber
    class Metadata
      attr_accessor :attributes

      def initialize(attributes)
        self.attributes = attributes
      end
    end

    attr_accessor :connection
    attr_accessor :logger

    def initialize(connection, logger = nil)
      @connection = connection
      @logger = logger
    end

    def logger
      @logger ||= Logger.new(STDOUT)
    end
    
    def subscription_callback
      lambda do |delivery_info, metadata, payload|
        hash_payload = JSON.parse payload

        event = {
            payload:       hash_payload,
            headers:       metadata[:headers],
            delivery_info: delivery_info,
            attributes:    metadata[:headers] ? hash_payload.merge(metadata[:headers]) : hash_payload
        }
        yield(Metadata.new(metadata), event)
      end
    end

    def subscribe(subscription = {}, subscribe_options = Philotic::DEFAULT_SUBSCRIBE_OPTIONS, &block)
      connection.connect!
      @exchange = connection.exchange

      subscription_settings = get_subscription_settings subscription, subscribe_options

      q = connection.channel.queue(subscription_settings[:queue_name], subscription_settings[:queue_options])

      q.bind(@exchange, arguments: subscription_settings[:arguments]) if subscription_settings[:arguments]

      q.subscribe(subscription_settings[:subscribe_options], &subscription_callback(&block))

    end

    def get_subscription_settings(subscription, subscribe_options)

      if subscription.is_a? String
        queue_name    = subscription
        subscription  = subscribe_options
        queue_options = Philotic::DEFAULT_NAMED_QUEUE_OPTIONS

      else
        queue_name           = subscription[:queue_name] || ''
        queue_options        = Philotic::DEFAULT_ANONYMOUS_QUEUE_OPTIONS
        subscribe_options    = subscribe_options.merge(subscription[:subscribe_options]) if subscription[:subscribe_options]
        arguments            = subscription[:arguments] || subscription
        arguments['x-match'] ||= 'all'
      end

      queue_options.merge!(subscription[:queue_options] || {})

      queue_options[:auto_delete] ||= true if queue_name == ''

      {
          queue_name:        queue_name,
          queue_options:     queue_options,
          arguments:         arguments,
          subscribe_options: subscribe_options,
      }
    end

    def acknowledge(message, up_to_and_including=false)
      connection.channel.acknowledge(message[:delivery_info].delivery_tag, up_to_and_including)
    end

    def reject(message, requeue=true)
      connection.channel.reject(message[:delivery_info].delivery_tag, requeue)
    end

    def subscribe_to_any(options = {})
      if block_given?
        subscribe(options.merge(:'x-match' => :any), &Proc.new)
      end
    end

    def endure
      while true
        Thread.pass
      end
    end
  end
end