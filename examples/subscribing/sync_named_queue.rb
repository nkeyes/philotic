#!/usr/bin/env ruby
$:.unshift File.expand_path('../../../lib', __FILE__)
$stdout.sync = true

require 'pry'
require 'philotic'


#explicitly create a named queue for this example
#ENV['INITIALIZE_NAMED_QUEUE'] = 'true'
#Philotic.initialize_named_queue!('test_queue', bindings: [{ :"x-match" => 'any', gender: :M, available: true }])


count = 0
Philotic::Subscriber.subscribe('test_queue') do |metadata, payload|
  count += 1
  print "#{payload[:payload]['message']} (#{count} total)                \r"
end
while true
  sleep 1
end
