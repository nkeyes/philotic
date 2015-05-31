require 'philotic/constants'

module Philotic
  class Publisher

    attr_accessor :connection
    attr_accessor :log_event_handler

    def initialize(connection)
      @connection = connection
    end

    def logger
      connection.logger
    end

    def config
      connection.config
    end

    def publish(event)
      metadata = {headers: event.headers}
      metadata.merge!(event.metadata) if event.metadata
      begin
        event.published = _publish(event.payload, metadata)
      rescue => e
        event.publish_error = e
        logger.error e.message
      end
      event
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
        log_event_published(:warn, metadata, payload, 'attempted to publish a message when publishing is disabled.')
        return false
      end
      connection.connect!
      unless connection.connected?
        log_event_published(:error, metadata, payload, 'unable to publish event, not connected to RabbitMQ')
        return false
      end
      metadata = merge_metadata(metadata)

      payload = normalize_payload_times(payload)

      connection.exchange.publish(payload.to_json, metadata)
      log_event_published(:debug, metadata, payload, 'published event')
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

    def on_publish_event(&block)
      @log_event_handler = block
    end

    def log_event_published(severity, metadata, payload, message)
      if @log_event_handler
        @log_event_handler.call(severity, metadata, payload, message)
      else
        logger.send(severity, "#{message}; metadata:#{metadata}, payload:#{payload.to_json}")
      end
    end
  end
end
