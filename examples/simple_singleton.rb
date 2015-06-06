#!/usr/bin/env ruby
$:.unshift File.expand_path('../../lib', __FILE__)
$stdout.sync = true

require 'philotic'
require 'awesome_print'

# override the message return handler
Philotic.config.message_return_handler = lambda do |basic_return, metadata, message|
  Philotic.logger.warn { "Message returned. reply_text: #{basic_return.reply_text}" }
end

Philotic.subscribe(header_key: 'header_1') do |message|
  ap message.attributes
end

# normally we'd do:
#
# Philotic.subscriber.endure
#
# to keep the parent thread alive while the subscribers do their thing
# but this infinite publish loop takes care of that
loop do
  Philotic::Message.publish({header_key: "header_#{[1, 2].sample}"}, {payload_key: 'payload_value'})
  # only send a message every two seconds so we can see whats going on
  sleep 0.1
end