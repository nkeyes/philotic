require 'awesome_print'
require 'active_support/all'

require 'pathname'

require 'logger'

require 'philotic/constants'


module Philotic
  mattr_accessor :logger
  mattr_accessor :log_event_handler

  def self.root
    ::Pathname.new File.expand_path('../../', __FILE__)
  end

  def self.env
    ENV['SERVICE_ENV'] || 'development'
  end

  def self.exchange
    Philotic::Connection.exchange
  end

  def self.initialize_named_queue!(queue_name, config, &block)
    config = config.deep_symbolize_keys

    raise "ENV['INITIALIZE_NAMED_QUEUE'] must equal 'true' to run Philotic.initialize_named_queue!" unless ENV['INITIALIZE_NAMED_QUEUE'] == 'true'

    if Philotic::Connection.connection.queue_exists? queue_name
      Philotic::Connection.channel.queue(queue_name, passive: true).delete
      Philotic.logger.info "deleted old queue. queue:#{queue_name}"
    end

    queue = queue_from_config(queue_name, config)

    bind_queue(queue, config)
    block.call(queue) if block
  end

  def self.bind_queue(queue, config)
    queue_exchange = exchange_from_config(config)
    bindings       = config[:bindings]
    bindings.each do |arguments|
      queue.bind(queue_exchange, {arguments: arguments})
      Philotic.logger.info "Added binding to queue. queue:#{queue.name} binding:#{arguments}"
    end

    Philotic.logger.info "Finished adding bindings to queue. queue:#{queue.name}"
  end

  def self.exchange_from_config(config)
    config[:exchange] ? Philotic::Connection.channel.headers(config[:exchange], durable: true) : exchange
  end

  def self.queue_from_config(queue_name, config)
    queue_options = DEFAULT_NAMED_QUEUE_OPTIONS.dup
    queue_options.merge!(config[:options] || {})

    Philotic::Connection.channel.queue(queue_name, queue_options).tap do
      Philotic.logger.info "Created queue. queue:#{queue_name}"
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
require 'philotic/logging'
