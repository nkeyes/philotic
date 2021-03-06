require 'json'
require 'bunny'
require 'logger'
require 'bunny'
require 'i18n/core_ext/hash'
require 'philotic/constants'
require 'philotic/config'
require 'philotic/publisher'
require 'philotic/subscriber'

module Philotic
  class Connection

    class TCPConnectionFailed < StandardError
      attr_reader :url

      def initialize(message, url)
        super("Could not establish TCP connection to #{url}: #{message}")
      end
    end

    extend Forwardable

    attr_reader :connection, :connection_attempts
    attr_accessor :logger

    attr_writer :publisher, :subscriber

    def initialize
      @connection_attempts = 0
    end

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
        logger.info { "Connected to RabbitMQ: #{config.sanitized_rabbit_url}" }
        set_exchange_return_handler!
        true
      else
        logger.error { "Failed to connect to RabbitMQ: #{config.sanitized_rabbit_url}" }
        false
      end
    end

    def start_connection!
      begin
        attempt_connection
      rescue ::Bunny::TCPConnectionFailed => e
        if connection_attempts < config.connection_attempts
          retry
        else
          attempts             = connection_attempts
          @connection_attempts = 0
          raise TCPConnectionFailed.new "Failed to connect to RabbitMQ server after #{attempts} attempts", config.sanitized_rabbit_url
        end
      end
    end

    def attempt_connection
      @connection_attempts += 1
      logger.warn { "Connecting to RabbitMQ: #{config.sanitized_rabbit_url}. Attempt #{connection_attempts} of #{config.connection_attempts}" } if connection_attempts > 1

      @connection = Bunny.new(config.rabbit_url, connection_settings)
      @connection.start
      @connection_attempts = 0
    end

    def connection_settings
      {
        automatically_recover: config.automatically_recover,
        network_recovery_interval: config.network_recovery_interval,
        continuation_timeout: config.continuation_timeout,
      }
    end

    def close
      logger.warn { "closing connection to RabbitMQ: #{config.sanitized_rabbit_url}" }
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
      @exchange ||= channel.send(config.exchange_type, config.exchange_name, durable: true)
    end

    def set_exchange_return_handler!
      exchange.on_return do |basic_return, metadata, payload|
        config.message_return_handler.call(basic_return, metadata, payload)
      end
    end

    def initialize_named_queue!(queue_name, config)
      raise RuntimeError.new 'Philotic.config.initialize_named_queues must be true to run Philotic.initialize_named_queue!' unless self.config.initialize_named_queues

      connect!
      queue_exists = connection.queue_exists? queue_name

      should_delete_queue = queue_exists && self.config.delete_existing_queues
      should_create_queue = !queue_exists || self.config.delete_existing_queues

      if should_delete_queue
        channel.queue(queue_name, passive: true).delete
        logger.info { "deleted old queue. queue: #{queue_name}" }
      end

      if should_create_queue
        config = config.deep_symbolize_keys
        queue  = queue_from_config(queue_name, config)
        bind_queue(queue, config)
      else
        logger.warn { "Queue #{queue_name} not created; it already exists. self.config.delete_existing_queues must be true to override." }
      end
    end

    def bind_queue(queue, config)
      queue_exchange = exchange_from_config(config)
      bindings       = config[:bindings]
      bindings.each do |arguments|
        queue.bind(queue_exchange, {arguments: arguments})
        logger.info { "Added binding to queue. queue: #{queue.name} binding: #{arguments}" }
      end

      logger.info { "Finished adding bindings to queue. queue: #{queue.name}" }
    end

    def exchange_from_config(config)
      config[:exchange] ? channel.send(self.config.exchange_type, config[:exchange], durable: true) : exchange
    end

    def queue_from_config(queue_name, config)
      queue_options = Philotic::DEFAULT_NAMED_QUEUE_OPTIONS.dup
      queue_options.merge!(config[:options] || {})

      channel.queue(queue_name, queue_options).tap do
        logger.info { "Created queue. queue:#{queue_name}" }
      end
    end

    def logger
      unless @logger
        @logger       = Logger.new(STDOUT)
        @logger.level = config.log_level
      end
      @logger
    end

    def_delegators :publisher, *(Philotic::Publisher.public_instance_methods(false) - [:connection, :config, :logger])
    def_delegators :subscriber, *(Philotic::Subscriber.public_instance_methods(false) - [:connection, :config, :logger])
  end
end
