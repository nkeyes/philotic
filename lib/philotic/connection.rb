require 'json'
require 'bunny'
require 'logger'

require 'philotic/config'
require 'philotic/publisher'
require 'philotic/subscriber'

module Philotic
  class Connection
    attr_reader :connection
    attr_accessor :logger

    attr_writer :publisher, :subscriber

    def publisher
      @publisher ||= Philotic::Publisher.new self
    end

    def subscriber
      @subscriber ||= Philotic::Subscriber.new self
    end

    def config
      @config ||= Philotic::Config.new self
    end

    def connect!
      return if connected?

      start_connection!

      if connected?
        logger.info "connected to RabbitMQ: #{config.rabbit_host}:#{config.rabbit_port}"
        set_exchange_return_handler!
        true
      else
        logger.error "failed connected to RabbitMQ; host:#{config.rabbit_host}"
        false
      end
    end

    def start_connection!
      @connection = Bunny.new(config.rabbit_url, connection_settings)
      @connection.start
    end

    def connection_settings
      {
          timeout:                   config.timeout.to_i,
          automatically_recover:     true,
          on_tcp_connection_failure: config.connection_failed_handler,
      }
    end

    def close
      logger.info "closing connection to RabbitMQ; host:#{config.rabbit_host}"
      connection.close if connected?
      @channel  = nil
      @exchange = nil
    end

    def connected?
      connection && connection.connected?
    end

    def channel
      @channel ||= connection.create_channel
    end

    def exchange
      @exchange ||= channel.headers(config.exchange_name, durable: true)
    end

    def set_exchange_return_handler!
      exchange.on_return do |basic_return, metadata, payload|
        config.message_return_handler.call(basic_return, metadata, payload)
      end
    end

    def initialize_named_queue!(queue_name, config)
      raise 'Philotic.config.initialize_named_queues must be true to run Philotic.initialize_named_queue!' unless self.config.initialize_named_queues

      connect!
      queue_exists = connection.queue_exists? queue_name

      should_delete_queue = queue_exists && self.config.delete_existing_queues
      should_create_queue = !queue_exists || self.config.delete_existing_queues

      if should_delete_queue
        channel.queue(queue_name, passive: true).delete
        logger.info "deleted old queue. queue: #{queue_name}"
      end

      if should_create_queue
        config = config.deep_symbolize_keys
        queue  = queue_from_config(queue_name, config)
        bind_queue(queue, config)
      else
        logger.warn "Queue #{queue_name} not created; it already exists. self.config.delete_existing_queues must be true to override."
      end
    end

    def bind_queue(queue, config)
      queue_exchange = exchange_from_config(config)
      bindings       = config[:bindings]
      bindings.each do |arguments|
        queue.bind(queue_exchange, {arguments: arguments})
        logger.info "Added binding to queue. queue: #{queue.name} binding: #{arguments}"
      end

      logger.info "Finished adding bindings to queue. queue: #{queue.name}"
    end

    def exchange_from_config(config)
      config[:exchange] ? channel.headers(config[:exchange], durable: true) : exchange
    end

    def queue_from_config(queue_name, config)
      queue_options = DEFAULT_NAMED_QUEUE_OPTIONS.dup
      queue_options.merge!(config[:options] || {})

      channel.queue(queue_name, queue_options).tap do
        logger.info "Created queue. queue:#{queue_name}"
      end
    end

    def logger
      unless @logger
        @logger = Logger.new(STDOUT)
        @logger.level = config.log_level
      end
      @logger
    end

    def publish(event)
      publisher.publish(event)
    end
  end
end
