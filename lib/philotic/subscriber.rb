module Philotic
  class Subscriber
    class Metadata
      attr_accessor :attributes

      def initialize(attributes)
        self.attributes = attributes
      end
    end

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

    def self.acknowledge(message, up_to_and_including=false)
      Philotic::Connection.channel.acknowledge(message[:delivery_info].delivery_tag, up_to_and_including)
    end

    def self.reject(message, requeue=true)
      Philotic::Connection.channel.reject(message[:delivery_info].delivery_tag, requeue)
    end

    def self.subscribe_to_any_or_all_of(any_or_all, options = {})
      arguments     = options[:arguments] || {}
      queue_options = options[:queue_options] || {}

      arguments['x-match'] = any_or_all

      if block_given?
        self.subscribe(options, &Proc.new)
      else
        self.subscribe(options)
      end
    end

    def self.subscribe_to_any_of(options = {}, &block)
      self.subscribe_to_any_or_all_of(:any, options, &block)
    end

    def self.subscribe_to_all_of(options = {}, &block)
      self.subscribe_to_any_or_all_of(:all, options, &block)
    end

    private
    def self._subscribe(options = {}, subscribe_options = Philotic::DEFAULT_SUBSCRIBE_OPTIONS)
      @exchange = Philotic::Connection.exchange

      if options.is_a? String
        queue_name    = options
        options       = subscribe_options
        queue_options = Philotic::DEFAULT_NAMED_QUEUE_OPTIONS

      else
        queue_name           = options[:queue_name] || ''
        queue_options        = Philotic::DEFAULT_ANONYMOUS_QUEUE_OPTIONS
        subscribe_options    = subscribe_options.merge(options[:subscribe_options]) if options[:subscribe_options]
        arguments            = options[:arguments] || options
        arguments['x-match'] ||= 'all'
      end

      queue_options.merge!(options[:queue_options] || {})

      queue_options[:auto_delete] ||= true if queue_name == ''

      callback = lambda do |delivery_info, metadata, payload|
        hash_payload = JSON.parse payload

        event = {
            payload:       hash_payload,
            headers:       metadata[:headers],
            delivery_info: delivery_info,
            attributes:    metadata[:headers] ? hash_payload.merge(metadata[:headers]) : hash_payload
        }
        Proc.new.call(Metadata.new(metadata), event)
      end
      q        = Philotic::Connection.channel.queue(queue_name, queue_options)

      q.bind(@exchange, arguments: arguments) if arguments

      q.subscribe(subscribe_options, &callback)

    end
  end
end
