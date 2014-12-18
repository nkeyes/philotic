require 'philotic/connection'

module Philotic
  class Publisher

    attr_accessor :connection
    attr_accessor :logger
    attr_accessor :log_event_handler

    def initialize(connection, logger = nil)
      @connection = connection
      @logger = logger
    end

    def logger
      @logger ||= Logger.new(STDOUT)
    end

    def config
      connection.config
    end

    def publish(event)
      message_metadata = {headers: event.headers}
      message_metadata.merge!(event.message_metadata) if event.message_metadata
      _publish(event.payload, message_metadata)
    end

    private
    def _publish(payload, message_metadata = {})
      if config.disable_publish
        log_event_published(:warn,  message_metadata, payload, 'attempted to publish a message when publishing is disabled.')
        return false
      end
      connection.connect!
      unless connection.connected?
        log_event_published(:error, message_metadata, payload, 'unable to publish event, not connected to RabbitMQ')
        return
      end
      message_metadata = merge_metadata(message_metadata)

      payload = normalize_payload_times(payload)

      connection.exchange.publish(payload.to_json, message_metadata)
      log_event_published(:debug, message_metadata, payload, 'published event')
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

    def merge_metadata(message_metadata)
      publish_defaults = {}
      Philotic::MESSAGE_OPTIONS.each do |key|
        publish_defaults[key] = config.send(key.to_s)
      end
      message_metadata           = publish_defaults.merge message_metadata
      message_metadata[:headers] ||= {}
      message_metadata[:headers] = {philotic_firehose: true}.merge(message_metadata[:headers])
      message_metadata
    end

    def on_publish_event(&block)
      @log_event_handler = block
    end

    def log_event_published(severity, metadata, payload, message)
      if @log_event_handler
        @log_event_handler.call(severity, metadata, payload, message)
      else
        logger.send(severity, "#{message}; message_metadata:#{metadata}, payload:#{payload.to_json}")
      end
    end
  end
end
