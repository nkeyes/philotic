module Philotic

  MESSAGE_OPTIONS    = [
      :routing_key,
      :persistent,
      :immediate,
      :mandatory,
      :content_type,
      :content_encoding,
      :priority,
      :message_id,
      :correlation_id,
      :reply_to,
      :type,
      :user_id,
      :app_id,
      :timestamp,
      :expiration,
  ]

  PHILOTIC_HEADERS = [
      :philotic_firehose,
      :philotic_product,
      :philotic_component,
      :philotic_message_type,
  ]

  DEFAULT_NAMED_QUEUE_OPTIONS     = {
      auto_delete: false,
      durable:     true
  }
  DEFAULT_ANONYMOUS_QUEUE_OPTIONS = {
      auto_delete: true,
      durable:     false
  }

  DEFAULT_SUBSCRIBE_OPTIONS = {}

end