require 'yaml'
require 'json'
require 'singleton'
require 'forwardable'
require 'cgi'
require 'bunny/session'

module Philotic
  module Config
    extend self

    ENV_PREFIX = 'PHILOTIC'

    DEFAULT_DISABLE_PUBLISH = false

    DEFAULT_RABBIT_SCHEME     = 'amqp'
    DEFAULT_RABBIT_HOST      = 'localhost'
    DEFAULT_RABBIT_PORT      = 5672
    DEFAULT_RABBIT_USER      = 'guest'
    DEFAULT_RABBIT_PASSWORD  = 'guest'
    DEFAULT_RABBIT_VHOST     = '%2f' # '/'
    DEFAULT_RABBIT_URL       = "#{DEFAULT_RABBIT_SCHEME}://#{DEFAULT_RABBIT_USER}:#{DEFAULT_RABBIT_PASSWORD}@#{DEFAULT_RABBIT_HOST}:#{DEFAULT_RABBIT_PORT}/#{DEFAULT_RABBIT_VHOST}"
    DEFAULT_EXCHANGE_NAME    = 'philotic.headers'
    DEFAULT_TIMEOUT = 2
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

    attr_writer :connection_failed_handler, :connection_loss_handler, :message_return_handler

    def connection_failed_handler
      @connection_failed_handler ||= lambda do |settings|
        Philotic.logger.error "RabbitMQ connection failure; host:#{rabbit_host}"
      end
    end

    def connection_loss_handler
      @connection_loss_handler ||= lambda do |conn, settings|
        Philotic.logger.warn "RabbitMQ connection loss; host:#{rabbit_host}"; conn.reconnect(false, 2)
      end
    end

    def message_return_handler
      @message_return_handler ||= lambda do |basic_return, metadata, payload|
        puts "Philotic message #{JSON.parse payload} was returned! reply_code = #{basic_return.reply_code}, reply_text = #{basic_return.reply_text} headers = #{metadata[:headers]}"
      end
    end

    def self.parse_rabbit_uri
      settings            = Bunny::Session.parse_uri(@rabbit_url || defaults[:rabbit_url])
      settings[:password] = settings.delete(:pass)

      %w[scheme host port user password vhost].each do |setting|
        setting       = setting.to_sym
        current_value = send("rabbit_#{setting}")

        # only use the value from the URI if the existing value is nil or the default
        if settings[setting] && [const_get("default_rabbit_#{setting}".upcase), nil].include?(current_value)
          send("rabbit_#{setting}=", settings[setting])
        end
      end

    end

    def self.rabbit_url
      self.parse_rabbit_uri
      "#{rabbit_scheme}://#{rabbit_user}:#{rabbit_password}@#{rabbit_host}:#{rabbit_port}/#{CGI.escape rabbit_vhost}"
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
