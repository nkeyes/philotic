require 'philotic/connection'

module Philotic
  module Publisher
    extend self

    def config
      Philotic::Config
    end

    def publish(event)
      message_metadata = {headers: event.headers}
      message_metadata.merge!(event.message_metadata) if event.message_metadata
      _publish(event.payload, message_metadata)
    end

    private
    def _publish(payload, message_metadata = {})
      Philotic.connect!
      unless Philotic::Connection.connected?
        Philotic.log_event_published(:error, message_metadata, payload, 'unable to publish event, not connected to RabbitMQ')
        return
      end
      message_metadata = merge_metadata(message_metadata)

      payload = normalize_payload_times(payload)

      return if config.disable_publish

      Philotic::Connection.exchange.publish(payload.to_json, message_metadata)
      Philotic.log_event_published(:debug, message_metadata, payload, 'published event')
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
  end
end
