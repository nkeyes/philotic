module Philotic
  class Subscriber
    def self.subscribe(options = {}, subscribe_options = Philotic::DEFAULT_SUBSCRIBE_OPTIONS)
      if block_given?
        if Philotic.connected?
          _subscribe(options, subscribe_options, &Proc.new)
        else
          Philotic.connect! do
            _subscribe(options, subscribe_options, &Proc.new)
          end
        end
      else
        if Philotic.connected?
          _subscribe(options, subscribe_options)
        else
          Philotic.connect! do
            _subscribe(options, subscribe_options)
          end
        end
      end

    end

    def self.subscribe_to_any_of(options = {})
      arguments = options[:arguments] || {}
      queue_options = options[:queue_options] || {}

      arguments['x-match'] = 'any'

      if block_given?
        self.subscribe(options, &Proc.new)
      else
        self.subscribe(options)
      end
    end

    def self.subscribe_to_all_of(options = {})
      arguments = options[:arguments] || {}
      queue_options = options[:queue_options] || {}

      arguments['x-match'] = 'all'

      if block_given?
        self.subscribe(options, &Proc.new)
      else
        self.subscribe(options)
      end
    end

    private
    def self._subscribe(options = {}, subscribe_options = Philotic::DEFAULT_SUBSCRIBE_OPTIONS)
      @@exchange = Philotic::Connection.exchange

      if options.is_a? String
        queue_name = options
        options = subscribe_options
        queue_options  = Philotic::DEFAULT_NAMED_QUEUE_OPTIONS

      else
        queue_name = options[:queue_name] || ''
        queue_options = Philotic::DEFAULT_ANONYMOUS_QUEUE_OPTIONS
        subscribe_options = subscribe_options.merge(options[:subscribe_options]) if options[:subscribe_options]
        arguments = options[:arguments] || options
        arguments['x-match'] ||= 'all'
      end

      queue_options.merge!(options[:queue_options] || {})

      queue_options[:auto_delete] ||= true if queue_name == ''

      callback = lambda do |metadata, payload|
        hash_payload = JSON.parse payload

        event = {
            payload: hash_payload,
            headers: metadata.attributes[:headers],
            attributes: metadata.attributes[:headers] ? hash_payload.merge(metadata.attributes[:headers]) : hash_payload
        }
        Proc.new.call(metadata, event)
      end
      q = AMQP.channel.queue(queue_name, queue_options)

      q.bind(@@exchange, arguments: arguments) if arguments

      q.subscribe(subscribe_options, &callback)

    end
  end
end
