require 'yaml'
require 'multi_json'
require 'oj'
require 'singleton'
require 'forwardable'
require 'cgi'
require 'bunny/session'
require 'logger'
require 'philotic/config/defaults'
require 'active_support/inflections'

module Philotic
  class Config

    include Defaults

    ENV_PREFIX = 'PHILOTIC'

    attr_accessor :connection

    def initialize(connection, config={})
      load_config config
      @connection = connection
    end

    def logger
      connection.logger
    end

    def log_level
      @log_level ||= defaults[:log_level].to_i
    end

    def connection_attempts
      @connection_retries ||= defaults[:connection_attempts].to_i
    end

    def prefetch_count
      @prefetch_count ||= defaults[:prefetch_count].to_i
    end

    attr_writer :message_return_handler

    def message_return_handler
      @message_return_handler ||= lambda do |basic_return, metadata, payload|
        logger.warn { "Philotic message #{JSON.parse payload} was returned! reply_code = #{basic_return.reply_code}, reply_text = #{basic_return.reply_text} headers = #{metadata[:headers]}" }
      end
    end

    def parse_rabbit_uri
      settings            = Bunny::Session.parse_uri(@rabbit_url || defaults[:rabbit_url])
      settings[:password] = settings.delete(:pass)

      %w[scheme host port user password vhost].each do |setting|
        setting       = setting.to_sym
        current_value = send("rabbit_#{setting}")

        # only use the value from the URI if the existing value is nil or the default
        if settings[setting] && [Defaults.const_get("rabbit_#{setting}".upcase), nil].include?(current_value)
          send("rabbit_#{setting}=", settings[setting])
        end
      end

    end

    def rabbit_url
      parse_rabbit_uri
      "#{rabbit_scheme}://#{rabbit_user}:#{rabbit_password}@#{rabbit_host}:#{rabbit_port}/#{CGI.escape rabbit_vhost}"
    end

    def sanitized_rabbit_url
      parse_rabbit_uri
      rabbit_url.gsub("#{rabbit_user}:#{rabbit_password}", '[USER_REDACTED]:[PASSWORD_REDACTED]')
    end

    def load_config(config)
      config.each do |k, v|
        mutator = "#{k}="
        send(mutator, v) if respond_to? mutator
      end
    end

    def load_file(filename, env = 'development')
      config = YAML.load_file(filename)
      load_config(config[env])
    end

    def serializations
      self.serializations = MultiJson.load(defaults[:serializations]) unless @serializations
      @serializations
    end

    def content_type
      Philotic::Serialization::Serializer.factory(serializations.last).content_type
    end
  end
end