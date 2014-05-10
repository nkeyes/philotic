#!/usr/bin/env ruby
$:.unshift File.expand_path('../../../lib', __FILE__)
$stdout.sync = true

require 'thread/channel'

require 'philotic'
require 'philotic/dummy_event'

EventMachine.run do
  # hit Control + C to stop
  Signal.trap("INT") { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }

  Philotic.logger= Logger.new('/dev/null')

  Philotic::Config.load_file(File.join(File.dirname(__FILE__), "../../", "philotic.yml.example"))

  Philotic::Connection.connect! do
    def send_message number
      dummy_event = Philotic::DummyEvent.new

      dummy_event.philotic_firehose = true
      dummy_event.philotic_product = 'rabbit'
      dummy_event.philotic_component = 'speed_test'
      dummy_event.philotic_event_type = 'ping'

      dummy_event.subject = "Hey"
      dummy_event.available = true
      dummy_event.gender = [:F, :M].sample

      dummy_event.message_metadata = { mandatory: true }
      dummy_event.message_metadata = { app_id: 'PHX' }
      dummy_event.message = "Message #{number}: Hey #{dummy_event.gender == :M ? 'dude' : 'dudette'}"

      dummy_event.publish
    end



    channel = Thread::Channel.new

    Thread.new do

      Thread.new do
        while num = channel.receive
          send_message num
          print "Sent message: #{num}                  \r"
        end
      end
      i = 1
      while true
        channel.send i
        i +=1
        sleep 0.0001
      end
    end
  end
end
