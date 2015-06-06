#!/usr/bin/env ruby
$:.unshift File.expand_path('../../../lib', __FILE__)
$stdout.sync = true

require 'philotic'
require 'awesome_print'

class NamedQueueConsumer < Philotic::Consumer

  # subscribe to an existing named queue
  subscribe_to :test_queue

  #use acknowledgements
  ack_messages

  # REQUEUE the message with RabbitMQ if consume throws these errors. I.e., something went wrong with the consumer
  # Only valid with ack_messages
  requeueable_errors PossiblyTransientErrorOne, PossiblyTransientErrorTwo

  # REJECT the message with RabbitMQ if consume throws these errors. I.e., The message is malformed/invalid
  # Only valid with ack_messages
  rejectable_errors BadMessageError

  def consume(message)
    ap named: message.attributes
  end
end

class AnonymousQueueConsumer < Philotic::Consumer

  # subscribe anonymously to a set of headers:
  # subscribe_to header_1: 'value_1',
  #              header_2: 'value_2',
  #              header_3: 'value_3'
  subscribe_to philotic_firehose: true

  def consume(message)
    ap anon: message.attributes
  end
end

#run the consumers
AnonymousQueueConsumer.subscribe
NamedQueueConsumer.subscribe

# keep the parent thread alive
Philotic.endure
