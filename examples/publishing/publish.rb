#!/usr/bin/env ruby
$:.unshift File.expand_path('../../../lib', __FILE__)
$stdout.sync = true

require 'pry'

require 'philotic'
require 'philotic/dummy_event'

EventMachine.run do
  # hit Control + C to stop
  #Signal.trap("INT") { EventMachine.stop }
  #Signal.trap("TERM") { EventMachine.stop }


  Philotic::Config.load_file(File.join(File.dirname(__FILE__), "../../", "philotic.yml"))

  #Philotic::Config.message_return_handler = Proc.new { |basic_return, metadata, payload|
  #  p "overridden"
  #  Philotic.logger.warn "#{JSON.parse payload} was returned! reply_code = #{basic_return.reply_code}, reply_text = #{basic_return.reply_text}"
  #}


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


      dummy_event.message_metadata = {mandatory: true}
      dummy_event.message_metadata = {app_id: 'PHX'}
      dummy_event.message = "Message #{number}: Hey #{dummy_event.gender == :M ? 'dude' : 'dudette'}"
      dummy_event.publish

      EM.add_timer rand/10 do
        send_message number + 1
      end
    end

    send_message 1

  end
end
