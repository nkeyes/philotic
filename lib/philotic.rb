require 'awesome_print'
require 'active_support/all'

require 'pathname'

require 'logger'

module Philotic
  mattr_accessor :logger
  mattr_accessor :log_event_handler

  CONNECTION_OPTIONS = [
      :rabbit_host,
      :connection_failed_handler,
      :connection_loss_handler,
      :timeout,
  ]
  EXCHANGE_OPTIONS = [
      :exchange_name,
      :message_return_handler,
  ]
  MESSAGE_OPTIONS = [
      :routing_key,
      :persistent,
      # :immediate,
      :mandatory,
      :content_type,
      :content_encoding,
      :priority,
      :message_id,
      :correlation_id,
      :reply_to,
      :type,
      :user_id,
      :app_id,
      :timestamp,
      :expiration,
  ]

  PHILOTIC_HEADERS = [
      :philotic_firehose,
      :philotic_product,
      :philotic_component,
      :philotic_event_type,
  ]

  DEFAULT_NAMED_QUEUE_OPTIONS = {
      auto_delete: false,
      durable: true
  }
  DEFAULT_ANONYMOUS_QUEUE_OPTIONS = {
      auto_delete: true,
      durable: false
  }

  DEFAULT_SUBSCRIBE_OPTIONS = {}

  def self.root
    ::Pathname.new File.expand_path('../../', __FILE__)
  end

  def self.env
    ENV['SERVICE_ENV'] || 'development'
  end

  def self.exchange
    Philotic::Connection.exchange
  end

  def self.delete_queue(queue_name, config, &block)
    config = config.deep_symbolize_keys

    connect! do
      queue_options = DEFAULT_NAMED_QUEUE_OPTIONS.dup
      queue_options.merge!(config[:options] || {})

      AMQP.channel.queue(queue_name, queue_options) do |old_queue|
        old_queue.delete(&block)
      end
    end
  end

  def self.initialize_named_queue!(queue_name, config, &block)
    config = config.deep_symbolize_keys

    raise "ENV['INITIALIZE_NAMED_QUEUE'] must equal 'true' to run Philotic.initialize_named_queue!" unless ENV['INITIALIZE_NAMED_QUEUE'] == 'true'

    delete_queue(queue_name, config) do
      Philotic::Connection.close do
        connect! do
          Philotic.logger.info "deleted old queue. queue:#{queue_name}"

          bindings = config[:bindings]

          queue_exchange = config[:exchange] ? AMQP.channel.headers(config[:exchange], durable: true) : exchange
          queue_options = DEFAULT_NAMED_QUEUE_OPTIONS.dup
          queue_options.merge!(config[:options] || {})

          AMQP.channel.queue(queue_name, queue_options) do |q|
            Philotic.logger.info "Created queue. queue:#{q.name}"
            bindings.each_with_index do |arguments, arguments_index|
              q.bind(queue_exchange, { arguments: arguments }) do
                Philotic.logger.info "Added binding to queue. queue:#{q.name} binding:#{arguments}"
                if arguments_index >= bindings.size - 1
                  Philotic.logger.info "Finished adding bindings to queue. queue:#{q.name}"
                  block.call(q) if block
                end
              end
            end
          end
        end
      end
    end
  end

  def self.logger
    @@logger ||= init_logger
  end

  def self.init_logger
    Logger.new(STDOUT)
  end

  def self.on_publish_event(&block)
    @@log_event_handler = block
  end

  def self.log_event_published(severity, metadata, payload, message)
    if @@log_event_handler
      @@log_event_handler.call(severity, metadata, payload, message)
    else
      logger.send(severity, "#{message}; message_metadata:#{metadata}, payload:#{payload.to_json}")
    end
  end

  def self.connected?
    Philotic::Connection.connected?
  end

  def self.connect! &block
    Philotic::Connection.connect! &block
  end
end

require 'philotic/version'
require 'philotic/connection'
require 'philotic/config'
require 'philotic/routable'
require 'philotic/event'
require 'philotic/publisher'
require 'philotic/subscriber'
