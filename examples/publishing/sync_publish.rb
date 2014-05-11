#!/usr/bin/env ruby
$:.unshift File.expand_path('../../../lib', __FILE__)
$stdout.sync = true

require 'philotic'
require 'philotic/dummy_event'

Philotic.logger= Logger.new('/dev/null')

Philotic::Config.load_file(File.join(File.dirname(__FILE__), "../../", "philotic.yml.example"))

#Philotic::Config.threaded_publish = true
#Philotic::Config.threaded_publish_pool_size = 3

Philotic::Connection.connect!
$dummy_event = Philotic::DummyEvent.new

$dummy_event.philotic_firehose = true
$dummy_event.philotic_product = 'rabbit'
$dummy_event.philotic_component = 'speed_test'
$dummy_event.philotic_event_type = 'ping'

$dummy_event.subject = "Hey"
$dummy_event.available = true

$dummy_event.message_metadata = { mandatory: true }
$dummy_event.message_metadata = { app_id: 'PHX' }

def send_message number
  $dummy_event.gender = [:F, :M].sample
  $dummy_event.message = "Message #{number}: Hey #{$dummy_event.gender == :M ? 'dude' : 'dudette'}"

  $dummy_event.publish

end

start = Time.now
i = 1
loop do
  send_message i
  print "Message rate: #{(i/(Time.now - start)).round(2)}/sec          \r"
  i+= 1
end
