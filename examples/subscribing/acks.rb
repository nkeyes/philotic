#!/usr/bin/env ruby
$:.unshift File.expand_path('../../../lib', __FILE__)
$stdout.sync = true

require 'philotic'
require 'awesome_print'

# sometimes ack
Philotic::Subscriber.subscribe('flaky_queue', ack: true) do |metadata, message|
  ap message[:attributes]
   [true, false].sample ? Philotic::Subscriber.acknowledge(message) : Philotic::Subscriber.reject(message)
end

# always ack
Philotic::Subscriber.subscribe('flaky_queue', ack: true) do |metadata, message|
  ap message[:attributes]
  Philotic::Subscriber.acknowledge(message, true)
end

# always reject
Philotic::Subscriber.subscribe('flaky_queue', ack: true) do |metadata, message|
  ap message[:attributes]
  Philotic::Subscriber.reject message
end
Philotic::Subscriber.endure