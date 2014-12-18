require 'active_support/all'
require 'pathname'

require 'philotic/constants'

module Philotic

  def self.root
    ::Pathname.new File.expand_path('../../', __FILE__)
  end

  def self.env
    ENV['SERVICE_ENV'] || 'development'
  end
end

require 'philotic/version'
require 'philotic/connection'
require 'philotic/config'
require 'philotic/routable'
require 'philotic/event'
require 'philotic/publisher'
require 'philotic/subscriber'
require 'philotic/logging'
