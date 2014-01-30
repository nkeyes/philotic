#!/usr/bin/env ruby
$:.unshift File.expand_path('../../../lib', __FILE__)
$stdout.sync = true

require 'pry'
require 'philotic'

EventMachine.run do
# hit Control + C to stop
  Signal.trap("INT") { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }

  Philotic::Config.load_file(File.join(File.dirname(__FILE__), "../../", "philotic.yml"))

  # explicitly create named queues for this example
  # ENV['INITIALIZE_NAMED_QUEUE'] must equal 'true' to run Philotic.initialize_named_queue!
  ENV['INITIALIZE_NAMED_QUEUE'] = 'true'
  Philotic.initialize_named_queue!('male_queue', :"x-match" => 'all', :gender => :M, :available => true) do
      Philotic.initialize_named_queue!('female_queue', :"x-match" => 'all', :gender => :F, :available => true)
  end

  # give it time to actually create the queue, then subscribe
  EM.add_timer(3) do
    Philotic::Subscriber.subscribe('male_queue') do |metadata, payload|
      p metadata.attributes
      p payload
    end
    Philotic::Subscriber.subscribe('female_queue') do |metadata, payload|
      p metadata.attributes
      p payload
    end
  end
end
