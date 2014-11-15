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
      publish_defaults = {}
      Philotic::MESSAGE_OPTIONS.each do |key|
        publish_defaults[key] = config.send(key.to_s)
      end
      message_metadata           = publish_defaults.merge message_metadata
      message_metadata[:headers] ||= {}
      message_metadata[:headers] = {philotic_firehose: true}.merge(message_metadata[:headers])

      payload.each { |k, v| payload[k] = v.utc if v.is_a? ActiveSupport::TimeWithZone }

      return if config.disable_publish

      unless Philotic::Connection.connected?
        Philotic.log_event_published(:error, message_metadata, payload, 'unable to publish event, not connected to amqp broker')
        return
      end
      Philotic::Connection.exchange.publish(payload.to_json, message_metadata)
      Philotic.log_event_published(:debug, message_metadata, payload, 'published event')
    end
  end
end
