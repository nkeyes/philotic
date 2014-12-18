require 'active_support/all'
require 'pathname'

require 'philotic/constants'
require 'philotic/connection'


module Philotic

  def self.root
    ::Pathname.new File.expand_path('../../', __FILE__)
  end

  def self.env
    ENV['SERVICE_ENV'] || 'development'
  end

  def self.connection
    @connection ||= Philotic::Connection.new
  end
end

require 'philotic/version'
require 'philotic/config'
require 'philotic/routable'
require 'philotic/event'
require 'philotic/publisher'
require 'philotic/subscriber'
require 'philotic/logging'
