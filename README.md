# Philotic

Lightweight, opinionated wrapper for using RabbitMQ headers exchanges

[![Build Status](https://travis-ci.org/nkeyes/philotic.png?branch=master)](https://travis-ci.org/nkeyes/philotic)
[![Gem Version](https://badge.fury.io/rb/philotic.png)](http://badge.fury.io/rb/philotic)
[![Dependency Status](https://gemnasium.com/nkeyes/philotic.svg)](https://gemnasium.com/nkeyes/philotic)
[![Code Climate](https://codeclimate.com/github/nkeyes/philotic/badges/gpa.svg)](https://codeclimate.com/github/nkeyes/philotic)
[![Test Coverage](https://codeclimate.com/github/nkeyes/philotic/badges/coverage.svg)](https://codeclimate.com/github/nkeyes/philotic)

Check out the [examples](https://github.com/nkeyes/philotic/tree/master/examples).
## Examples
### Using `Philotic` as a singleton
```Ruby
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
  sleep 2
end
```

### Using an instance of `Philotic::Connection`
```Ruby
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
```

### Tested with the following Rubies
* 2.0.0
* 2.1.x
* 2.2.x
* rbx-2
* ruby-head
