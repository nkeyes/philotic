#!/usr/bin/env ruby
$:.unshift File.expand_path('../../../lib', __FILE__)
$stdout.sync = true

require 'philotic'
require 'philotic/dummy_message'


Philotic.logger.level = Logger::WARN

@message = Philotic::DummyMessage.new

@message.philotic_firehose   = true
@message.philotic_product    = 'rabbit'
@message.philotic_component  = 'speed_test'
@message.philotic_message_type = 'ping'

@message.subject   = 'Hey'
@message.available = true

@message.metadata = {mandatory: true}
@message.metadata = {app_id: 'PHX'}

def send_message number
  @message.hue  = [:F, :M].sample
  @message.message = "Message #{number}: Hue - #{@message.hue == :M ? 'mauve' : 'fuchsia'}"

  Philotic.publish @message

end

start = Time.now
i     = 1
loop do
  send_message i
  print "Message rate: #{(i/(Time.now - start)).round(2)}/sec          \r"
  i+= 1
  sleep 0.001
end
