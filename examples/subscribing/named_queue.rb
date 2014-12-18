#!/usr/bin/env ruby
$:.unshift File.expand_path('../../../lib', __FILE__)
$stdout.sync = true

require 'philotic'
require 'awesome_print'

philotic = Philotic::Connection.new

philotic.subscriber.subscribe('test_queue') do |metadata, message|
  ap message[:attributes]
end

philotic.subscriber.endure
