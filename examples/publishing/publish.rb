#!/usr/bin/env ruby
$:.unshift File.expand_path('../../../lib', __FILE__)
$stdout.sync = true

require 'philotic'
require 'philotic/dummy_event'


Philotic.logger.level = Logger::WARN

@event = Philotic::DummyEvent.new

@event.philotic_firehose   = true
@event.philotic_product    = 'rabbit'
@event.philotic_component  = 'speed_test'
@event.philotic_event_type = 'ping'

@event.subject   = 'Hey'
@event.available = true

@event.metadata = {mandatory: true}
@event.metadata = {app_id: 'PHX'}

def send_message number
  @event.gender  = [:F, :M].sample
  @event.message = "Message #{number}: Hey #{@event.gender == :M ? 'dude' : 'dudette'}"

  Philotic.publish @event

end

start = Time.now
i     = 1
loop do
  send_message i
  print "Message rate: #{(i/(Time.now - start)).round(2)}/sec          \r"
  i+= 1
  sleep 0.001
end
