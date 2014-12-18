#!/usr/bin/env ruby
$:.unshift File.expand_path('../../../lib', __FILE__)
$stdout.sync = true

require 'philotic'
require 'awesome_print'

philotic = Philotic::Connection.new


# sometimes ack
philotic.subscriber.subscribe('flaky_queue', ack: true) do |metadata, message|
  ap message[:attributes]
   [true, false].sample ? philotic.subscriber.acknowledge(message) : philotic.subscriber.reject(message)
end

# always ack
philotic.subscriber.subscribe('flaky_queue', ack: true) do |metadata, message|
  ap message[:attributes]
  philotic.subscriber.acknowledge(message, true)
end

# always reject
philotic.subscriber.subscribe('flaky_queue', ack: true) do |metadata, message|
  ap message[:attributes]
  philotic.subscriber.reject message
end
philotic.subscriber.endure