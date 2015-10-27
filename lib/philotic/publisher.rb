require 'philotic/constants'
require 'philotic/serialization'

module Philotic
  class Publisher

    attr_accessor :connection
    attr_accessor :log_message_handler

    def initialize(connection)
      @connection = connection
    end

    def logger
      connection.logger
    end

    def config
      connection.config
    end

    def publish(message)
      metadata = {headers: message.headers}
      metadata.merge!(message.metadata) if message.metadata
      begin
        message.published = _publish(message.payload, metadata)
      rescue => e
        message.publish_error = e
        logger.error e.message
        raise e if config.raise_error_on_publish
      end
      message
    end

    def normalize_payload_times(payload)
      payload.each do |k, v|
        if v.respond_to?(:utc)
          payload[k] = v.utc
        elsif v.respond_to?(:to_utc)
          payload[k] = v.to_utc
        end
      end
    end

    private
    def _publish(payload, metadata = {})
      if config.disable_publish
        log_message_published(:warn, metadata, payload, 'attempted to publish a message when publishing is disabled.')
        return false
      end
      connection.connect!
      unless connection.connected?
        log_message_published(:error, metadata, payload, 'unable to publish message, not connected to RabbitMQ')
        return false
      end
      metadata = merge_metadata(metadata)

      payload = normalize_payload_times(payload)

      connection.exchange.publish(Philotic::Serialization::Serializer.dump(payload, metadata), metadata)
      log_message_published(:debug, metadata, payload, 'published message')
      true
    end

    def merge_metadata(metadata)
      publish_defaults = {}
      Philotic::MESSAGE_OPTIONS.each do |key|
        publish_defaults[key] = config.send(key.to_s)
      end
      metadata           = publish_defaults.merge metadata
      metadata[:headers] ||= {}
      metadata[:headers] = {philotic_firehose: true}.merge(metadata[:headers])
      metadata
    end

    def on_publish_message(&block)
      @log_message_handler = block
    end

    def log_message_published(severity, metadata, payload, message)
      if @log_message_handler
        @log_message_handler.call(severity, metadata, payload, message)
      else
        logger.send(severity, "#{message}; metadata:#{metadata}, payload:#{payload.to_json}")
      end
    end
  end
end
