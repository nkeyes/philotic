#!/usr/bin/env ruby
$:.unshift File.expand_path('../../../lib', __FILE__)
$stdout.sync = true

require 'philotic'
require 'awesome_print'

# sometimes ack
Philotic.subscribe('flaky_queue', manual_ack: true) do |message|
  ap message.attributes
   [true, false].sample ? acknowledge(message) : reject(message)
end

# always ack
Philotic.subscribe('flaky_queue', manual_ack: true) do |message|
  ap message.attributes
  acknowledge(message, true)
end

# always reject
Philotic.subscribe('flaky_queue', manual_ack: true) do |message|
  ap message.attributes
  reject message
end
Philotic.subscriber.endure