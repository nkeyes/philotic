#!/usr/bin/env ruby
$:.unshift File.expand_path( '../../../lib', __FILE__ )
$stdout.sync = true

require 'philotic'

EventMachine.run do
# hit Control + C to stop
  Signal.trap("INT")  { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }
  
  queue_after_initialize_handler = Proc.new do |q|
    Philotic.logger.info "Queue '#{q.name}' initialized: #{q.bindings}"
  end
  # consume ansible + subspace + new_message events
  ansible_arguments = {
    "x-match" => :all,
    event_bus_product: :ansible,
    philotic_component: :subspace,
    philotic_event_type: :new_message,
  }
  Philotic.initialize_named_queue!('ansible.new_messages', ansible_arguments, &queue_after_initialize_handler)

  
  EM.add_timer(5) { EM.stop }
end
