#!/usr/bin/env ruby
$:.unshift File.expand_path('../../../lib', __FILE__)
$stdout.sync = true

require 'philotic'
require 'awesome_print'

# sometimes ack
Philotic.subscribe('flaky_queue', ack: true) do |event|
  ap event.attributes
   [true, false].sample ? acknowledge(event) : reject(event)
end

# always ack
Philotic.subscribe('flaky_queue', ack: true) do |event|
  ap event.attributes
  acknowledge(event, true)
end

# always reject
Philotic.subscribe('flaky_queue', ack: true) do |event|
  ap event.attributes
  reject event
end
Philotic.subscriber.endure