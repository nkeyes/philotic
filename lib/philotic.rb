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

    bindings = config[:bindings]

    queue_exchange = config[:exchange] ? Philotic::Connection.channel.headers(config[:exchange], durable: true) : exchange
    queue_options  = DEFAULT_NAMED_QUEUE_OPTIONS.dup
    queue_options.merge!(config[:options] || {})

    q = Philotic::Connection.channel.queue(queue_name, queue_options)
    Philotic.logger.info "Created queue. queue:#{q.name}"
    bindings.each do |arguments|
      q.bind(queue_exchange, {arguments: arguments})
      Philotic.logger.info "Added binding to queue. queue:#{q.name} binding:#{arguments}"
    end

    Philotic.logger.info "Finished adding bindings to queue. queue:#{q.name}"
    block.call(q) if block
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
