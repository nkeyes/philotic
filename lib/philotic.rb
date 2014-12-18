require 'active_support/all'
require 'pathname'

require 'philotic/constants'
require 'philotic/connection'


module Philotic
  class << self
    extend Forwardable

    def root
      ::Pathname.new File.expand_path('../../', __FILE__)
    end

    def env
      ENV['SERVICE_ENV'] || 'development'
    end

    def connection
      @connection ||= Philotic::Connection.new
    end

    def method_missing(method, *args, &block)
      connection.send(method, *args, &block)
    end

    def_delegators :connection, *(Philotic::Connection.public_instance_methods(false) - [:connection])

  end

end

require 'philotic/version'
require 'philotic/config'
require 'philotic/routable'
require 'philotic/event'
require 'philotic/publisher'
require 'philotic/subscriber'
require 'philotic/logging'
