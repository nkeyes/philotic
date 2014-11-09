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
        yield if block_given?
        return
      end

      connection_settings = {
          timeout:                   config.timeout.to_i,
          automatically_recover:     true,
          on_tcp_connection_failure: config.connection_failed_handler,
      }

      @connection = Bunny.new(config.rabbit_url, connection_settings)
      @connection.start

      if connected?
        Philotic.logger.info "connected to RabbitMQ; host:#{config.rabbit_host}"
      else
        Philotic.logger.warn "failed connected to RabbitMQ; host:#{config.rabbit_host}"
      end

      #@connection.on_tcp_connection_loss do |cl, settings|
      #  config.method(:connection_loss_handler).call.call(cl, settings)
      #end
      #
      #@connection.after_recovery do |conn, settings|
      #  Philotic.logger.info "Connection recovered, now connected to #{config.rabbit_host}"
      #end

      setup_exchange_handler!
      yield if block_given?

    end

    def close
      Philotic.logger.info "closing connection to RabbitMQ; host:#{config.rabbit_host}"
      connection.close if connected?
      yield if block_given?
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

    def setup_exchange_handler!
      exchange.on_return do |basic_return, metadata, payload|
        config.method(:message_return_handler).call.call(basic_return, metadata, payload)
      end
    end
  end
end
