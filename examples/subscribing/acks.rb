#!/usr/bin/env ruby
$:.unshift File.expand_path('../../../lib', __FILE__)
$stdout.sync = true

require 'philotic'
require 'awesome_print'

# sometimes ack
Philotic.subscriber.subscribe('flaky_queue', ack: true) do |metadata, message|
  ap message[:attributes]
   [true, false].sample ? Philotic.subscriber.acknowledge(message) : Philotic.subscriber.reject(message)
end

# always ack
Philotic.subscriber.subscribe('flaky_queue', ack: true) do |metadata, message|
  ap message[:attributes]
  Philotic.subscriber.acknowledge(message, true)
end

# always reject
Philotic.subscriber.subscribe('flaky_queue', ack: true) do |metadata, message|
  ap message[:attributes]
  Philotic.subscriber.reject message
end
Philotic.subscriber.endure