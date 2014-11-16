require 'singleton'
require 'json'
require 'bunny'

require 'philotic/config'

module Philotic
  module Connection
    extend self
    attr_reader :connection

    def config
      Philotic::Config
    end

    def connect!
      if connected?
        Philotic.logger.info "already connected to RabbitMQ; host:#{config.rabbit_host}"
        return
      end

      start_connection!

      if connected?
        Philotic.logger.info "connected to RabbitMQ; host:#{config.rabbit_host}"
        set_exchange_return_handler!
        true
      else
        Philotic.logger.warn "failed connected to RabbitMQ; host:#{config.rabbit_host}"
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
      Philotic.logger.info "closing connection to RabbitMQ; host:#{config.rabbit_host}"
      connection.close if connected?
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
  end
end
