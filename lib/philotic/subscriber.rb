module Philotic
  class Subscriber
    def self.subscribe(options = {}, subscribe_options = Philotic::DEFAULT_SUBSCRIBE_OPTIONS, &block)
      if Philotic.connected?
        _subscribe(options, subscribe_options, &block)
      else
        Philotic.connect! do
          _subscribe(options, subscribe_options, &block)
        end
      end
    end

    def self.subscribe_to_any_of(options = {}, &block)
      arguments = options[:arguments] || {}
      queue_options = options[:queue_options] || {}

      arguments['x-match'] = 'any'

      self.subscribe(options, &block)
    end

    def self.subscribe_to_all_of(options = {}, &block)
      arguments = options[:arguments] || {}
      queue_options = options[:queue_options] || {}

      arguments['x-match'] = 'all'

      self.subscribe(options, &block)
    end

    private
    def self._subscribe(options = {}, subscribe_options = Philotic::DEFAULT_SUBSCRIBE_OPTIONS, &block)
      @@exchange = Philotic::Connection.exchange

      if options.is_a? String
        queue_name = options
        queue_options = Philotic::DEFAULT_NAMED_QUEUE_OPTIONS
      else
        queue_name = options[:queue_name] || ""

        queue_options = Philotic::DEFAULT_ANONYMOUS_QUEUE_OPTIONS.merge(options[:queue_options] || {})
        subscribe_options = subscribe_options.merge(options[:subscribe_options]) if options[:subscribe_options]
        arguments = options[:arguments] || options
        arguments['x-match'] ||= 'all'
      end

      queue_options[:auto_delete] ||= true if queue_name == ""

      callback = Proc.new do |metadata, payload|
        hash_payload = JSON.parse payload

        event = {
            :payload => hash_payload,
            :headers => metadata.attributes[:headers],
            :attributes => metadata.attributes[:headers] ? hash_payload.merge(metadata.attributes[:headers]) : hash_payload
        }
        block.call(metadata, event)
      end
      q = AMQP.channel.queue(queue_name, queue_options)

      q.bind(@@exchange, arguments: arguments) if arguments

      q.subscribe(subscribe_options, &callback)

    end
  end
end
