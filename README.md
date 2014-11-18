# Philotic

Lightweight, opinionated wrapper for using RabbitMQ headers exchanges

[![Gem Version](https://badge.fury.io/rb/philotic.png)](http://badge.fury.io/rb/philotic)
[![Build Status](https://travis-ci.org/nkeyes/philotic.png?branch=master)](https://travis-ci.org/nkeyes/philotic)
[![Code Climate](https://codeclimate.com/github/nkeyes/philotic/badges/gpa.svg)](https://codeclimate.com/github/nkeyes/philotic)
[![Test Coverage](https://codeclimate.com/github/nkeyes/philotic/badges/coverage.svg)](https://codeclimate.com/github/nkeyes/philotic)

Check out the [examples](https://github.com/nkeyes/philotic/tree/master/examples).

## Simple Example
```Ruby
require 'philotic'
require 'awesome_print'

# override the message return handler
Philotic::Config.message_return_handler = lambda do |basic_return, metadata, message|
  Philotic.logger.warn "Message returned. reply_text: #{basic_return.reply_text}"
end

Philotic::Subscriber.subscribe(header_key: 'header_1') do |metadata, message|
  ap message[:attributes]
end

# normally we'd do:
#
# Philotic::Subscriber.endure
#
# to keep the parent thread alive while the subscribers do their thing
# but this infinite publish loop takes care of that
loop do
  Philotic::Event.publish({header_key: "header_#{[1, 2].sample}"}, {payload_key: 'payload_value'})

  # only send a message every two seconds so we can see whats going on
  sleep 2
end
```

### Tested with the following Rubies
* 1.9.3
* 2.0.0
* 2.1.0
* jruby-19mode
* ruby-head
* jruby-head
