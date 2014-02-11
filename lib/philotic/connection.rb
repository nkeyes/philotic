require 'singleton'
require 'json'
require 'amqp'
require "amqp/extensions/rabbitmq"
require 'amqp/utilities/event_loop_helper'

module Philotic
  module Connection
    extend self
    attr_reader :connection

    def config
      Philotic::Config
    end

    def connect! &block
      if connected?
        Philotic.logger.info "already connected to RabbitMQ; host:#{config.rabbit_host}"
        block.call if block
        return
      end

      AMQP::Utilities::EventLoopHelper.run do
        connection_settings = {
            host: config.rabbit_host,
            port: config.rabbit_port,
            user: config.rabbit_user,
            password: config.rabbit_password,
            vhost: config.rabbit_vhost,
            timeout: config.timeout,
            on_tcp_connection_failure: config.connection_failed_handler,
        }

        AMQP.start(connection_settings, logging: true) do |connection, connect_ok|
          @connection = connection

          if connected?
            Philotic.logger.info "connected to RabbitMQ; host:#{config.rabbit_host}"
          else
            Philotic.logger.warn "failed connected to RabbitMQ; host:#{config.rabbit_host}"
          end


          AMQP.channel.auto_recovery = true

          @connection.on_tcp_connection_loss do |cl, settings|
            config.method(:connection_loss_handler).call.call(cl, settings)
          end

          @connection.after_recovery do |conn, settings|
            Philotic.logger.info "Connection recovered, now connected to #{config.rabbit_host}"
          end

          setup_exchange_handler!
          block.call if block

        end #AMQP.start
      end
    end

    def close &block
      if connected?
        connection.close &block
      else
        block.call
      end
    end

    def connected?
      connection && connection.connected?
    end

    def exchange
      AMQP.channel.headers(config.exchange_name, durable: true)
    end

    def setup_exchange_handler!
      exchange.on_return do |basic_return, metadata, payload|
        config.method(:message_return_handler).call.call(basic_return, metadata, payload)
      end
    end
  end
end
