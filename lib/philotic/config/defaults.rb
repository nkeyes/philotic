require 'logger'

module Philotic
  class Config
    module Defaults

      DISABLE_PUBLISH         = false
      INITIALIZE_NAMED_QUEUES = false
      DELETE_EXISTING_QUEUES  = false
      LOG_LEVEL               = Logger::DEBUG
      RABBIT_SCHEME           = 'amqp'
      RABBIT_HOST             = 'localhost'
      RABBIT_PORT             = 5672
      RABBIT_USER             = 'guest'
      RABBIT_PASSWORD         = 'guest'
      RABBIT_VHOST            = '%2f' # '/'
      RABBIT_URL              = "#{RABBIT_SCHEME}://#{RABBIT_USER}:#{RABBIT_PASSWORD}@#{RABBIT_HOST}:#{RABBIT_PORT}/#{RABBIT_VHOST}"
      EXCHANGE_NAME           = 'philotic.headers'
      TIMEOUT                 = 2
      ROUTING_KEY             = nil
      PERSISTENT              = false
      IMMEDIATE               = false
      MANDATORY               = false
      SERIALIZATIONS          = '["json"]' # serializations is expected to be a JSON ray of strings
      CONTENT_ENCODING        = nil
      PRIORITY                = nil
      MESSAGE_ID              = nil
      CORRELATION_ID          = nil
      REPLY_TO                = nil
      TYPE                    = nil
      USER_ID                 = nil
      APP_ID                  = nil
      TIMESTAMP               = nil
      EXPIRATION              = nil
      CONNECTION_ATTEMPTS     = 3
      PREFETCH_COUNT          = 0
      RAISE_ERROR_ON_PUBLISH  = false
      ENCRYPTION_KEY          = nil

      def defaults
        @defaults ||= Hash[Philotic::Config::Defaults.constants.map do |c|
                             key = c.downcase.to_sym

                             env_key = "#{ENV_PREFIX}_#{key}".upcase

                             [key, ENV[env_key] || Philotic::Config::Defaults.const_get(c)]
                           end
        ]
      end

      def self.included(base)
        Philotic::Config::Defaults.constants.each do |c|
          attr_symbol = c.downcase.to_sym
          base.send(:attr_writer, attr_symbol)
          base.class_eval %Q{
          def #{attr_symbol}
            @#{attr_symbol} ||= defaults[:#{attr_symbol}]
          end
        }
        end
      end
    end
  end
end
