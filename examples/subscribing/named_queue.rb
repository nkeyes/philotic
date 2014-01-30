#!/usr/bin/env ruby
$:.unshift File.expand_path( '../../../lib', __FILE__ )
$stdout.sync = true

require 'pry'
require 'philotic'

EventMachine.run do
# hit Control + C to stop
  Signal.trap("INT")  { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }
  
  #explicitly create a named queue for this example
  Philotic.initialize_named_queue!('test_queue', :"x-match" => 'any', :gender => :M, :available => true)
  
  # give it time to actually create the queue, then subscribe
  EM.add_timer(3) do
    Philotic::Subscriber.subscribe('test_queue') do |metadata, payload|
      p metadata.attributes
      p payload
    end
  end
end
