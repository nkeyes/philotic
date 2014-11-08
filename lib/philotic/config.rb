require 'yaml'
require 'json'
require 'singleton'
require 'forwardable'

module Philotic
  module Config
    extend self

    ENV_PREFIX = 'PHILOTIC'

    DEFAULT_DISABLE_PUBLISH = false

    DEFAULT_RABBIT_HOST               = 'localhost'
    DEFAULT_RABBIT_PORT               = 5672
    DEFAULT_RABBIT_USER               = 'guest'
    DEFAULT_RABBIT_PASSWORD           = 'guest'
    DEFAULT_RABBIT_VHOST              = '/'
    DEFAULT_EXCHANGE_NAME             = 'philotic.headers'
    DEFAULT_CONNECTION_FAILED_HANDLER = lambda { |settings| Philotic.logger.error "RabbitMQ connection failure; host:#{rabbit_host}" }
    DEFAULT_CONNECTION_LOSS_HANDLER   = lambda { |conn, settings| Philotic.logger.warn "RabbitMQ connection loss; host:#{rabbit_host}"; conn.reconnect(false, 2) }
    DEFAULT_MESSAGE_RETURN_HANDLER    = lambda { |basic_return, metadata, payload| Philotic.logger.warn "Philotic message #{JSON.parse payload} was returned! reply_code = #{basic_return.reply_code}, reply_text = #{basic_return.reply_text} headers = #{metadata.properties}"; }
    DEFAULT_TIMEOUT                   = 2

    DEFAULT_ROUTING_KEY      = nil
    DEFAULT_PERSISTENT       = true
    # DEFAULT_IMMEDIATE = false
    DEFAULT_MANDATORY        = true
    DEFAULT_CONTENT_TYPE     = nil
    DEFAULT_CONTENT_ENCODING = nil
    DEFAULT_PRIORITY         = nil
    DEFAULT_MESSAGE_ID       = nil
    DEFAULT_CORRELATION_ID   = nil
    DEFAULT_REPLY_TO         = nil
    DEFAULT_TYPE             = nil
    DEFAULT_USER_ID          = nil
    DEFAULT_APP_ID           = nil
    DEFAULT_TIMESTAMP        = nil
    DEFAULT_EXPIRATION       = nil

    def defaults
      @defaults ||= Hash[Config.constants.select { |c| c.to_s.start_with? 'DEFAULT_' }.collect do |c|
        key = c.slice(8..-1).downcase.to_sym

        env_key = "#{ENV_PREFIX}_#{key}".upcase

        [key, ENV[env_key] || Config.const_get(c)]
      end
      ]
    end

    Config.constants.each do |c|
      if c.to_s.start_with? 'DEFAULT_'
        attr_symbol = c.slice(8..-1).downcase.to_sym
        attr_writer attr_symbol
        class_eval %Q{
          def #{attr_symbol}
            @#{attr_symbol} ||= defaults[:#{attr_symbol}]
          end
        }
      end
    end

    def load(config)
      Philotic.logger # ensure the logger can be created, so we crash early if it can't

      config.each do |k, v|
        mutator = "#{k}="
        send(mutator, v) if respond_to? mutator
      end
    end

    def load_file(filename, env = 'development')
      config = YAML.load_file(filename)
      load(config[env])
    end
  end
end
