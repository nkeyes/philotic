#!/usr/bin/env ruby
$:.unshift File.expand_path('../../../lib', __FILE__)
$stdout.sync = true

require 'philotic'

EventMachine.run do
# hit Control + C to stop
#  Signal.trap("INT")  { EventMachine.stop }
#  Signal.trap("TERM") { EventMachine.stop }

  Philotic::Config.load_file(File.join(File.dirname(__FILE__), "../../", "philotic.yml"))


  Philotic::Subscriber.subscribe(event_bus_fire_hose: true) do |metadata, payload|
    p metadata.attributes
    p payload
  end
end
