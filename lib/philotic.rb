require 'pathname'

module Philotic
  class << self
    def root
      ::Pathname.new File.expand_path('../../', __FILE__)
    end
  end

end

require 'philotic/constants'
require 'philotic/singleton'

require 'philotic/connection'
require 'philotic/version'
require 'philotic/config'
require 'philotic/message'
require 'philotic/publisher'
require 'philotic/subscriber'
require 'philotic/consumer'
require 'philotic/logging'
