require 'philotic/connection'

module Philotic
  class << self
    extend Forwardable

    def connection
      @connection ||= Philotic::Connection.new
    end

    def_delegators :connection, *(Philotic::Connection.public_instance_methods(false) - [:connection])
  end
end