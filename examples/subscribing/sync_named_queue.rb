#!/usr/bin/env ruby
$:.unshift File.expand_path('../../../lib', __FILE__)
$stdout.sync = true

require 'pry'
require 'philotic'


#explicitly create a named queue for this example
#ENV['INITIALIZE_NAMED_QUEUE'] = 'true'
#Philotic.initialize_named_queue!('test_queue', bindings: [{ :"x-match" => 'any', gender: :M, available: true }])


# give it time to actually create the queue, then subscribe
Philotic::Subscriber.subscribe('test_queue') do |metadata, payload|
  print "#{payload[:payload]['message']}                \r"
end
while true
  sleep 1
end
