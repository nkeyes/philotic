#!/usr/bin/env ruby
$:.unshift File.expand_path('../../lib', __FILE__)
$stdout.sync = true

require 'philotic'
require 'awesome_print'

philotic = Philotic::Connection.new

# override the message return handler
philotic.config.message_return_handler = lambda do |basic_return, metadata, message|
  philotic.logger.warn { "Message returned. reply_text: #{basic_return.reply_text}" }
end

philotic.subscribe(header_key: 'header_1') do |message|
  ap message.attributes
end

# normally we'd do:
#
# philotic.subscriber.endure
#
# to keep the parent thread alive while the subscribers do their thing
# but this infinite publish loop takes care of that
loop do
  message = Philotic::Message.new({header_key: "header_#{[1, 2].sample}"}, {payload_key: 'payload_value'})
  philotic.publish message
  # only send a message every two seconds so we can see whats going on
  sleep 2
end