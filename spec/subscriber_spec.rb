require 'spec_helper'
require 'philotic/dummy_event'

describe Philotic::Subscriber do
  let(:subscriber) do
    subscriber = Philotic::Subscriber.new(arguments: {'x-match' => 'any', philotic_firehose: true}) do |metadata, payload|
      true
    end
    subscriber
  end

  describe "subscribe" do
    xit "should call AMQP.channel.queue with the right values" do
      queue = double(AMQP::Queue)
      queue.stub(:bind) { queue }
      queue.stub(:subscribe) { queue }
      channel = double(AMQP::Channel)
      exchange = double(AMQP::Exchange)
      channel.stub(:queue) { queue }
      channel.stub(:headers) { exchange }
      AMQP.stub(:channel) { channel }

      channel.should_receive(:queue).with("", {auto_delete: true, durable: false})
      queue.should_receive(:bind).with(exchange, {arguments: {"x-match" => "any", philotic_firehose: true}})
      queue.should_receive(:subscribe).with({})
      Philotic::Subscriber.subscribe(arguments: {'x-match' => 'any', philotic_firehose: true}) do |metadata, payload|
        true
      end
    end
  end

  describe "subscribe_to_any_of" do
    xit "should call AMQP.channel.queue with the right values" do
      queue = double(AMQP::Queue)
      queue.stub(:bind) { queue }
      queue.stub(:subscribe) { queue }
      channel = double(AMQP::Channel)
      exchange = double(AMQP::Exchange)
      channel.stub(:queue) { queue }
      channel.stub(:headers) { exchange }
      AMQP.stub(:channel) { channel }

      channel.should_receive(:queue).with("", {auto_delete: true, durable: false})
      queue.should_receive(:bind).with(exchange, {arguments: {"x-match" => "any", philotic_firehose: true}})
      queue.should_receive(:subscribe).with({})
      Philotic::Subscriber.subscribe_to_any_of(arguments: {philotic_firehose: true}) do |metadata, payload|
        true
      end
    end
  end

  describe "subscribe_to_all_of" do
    xit "should call AMQP.channel.queue with the right values" do
      queue = double(AMQP::Queue)
      queue.stub(:bind) { queue }
      queue.stub(:subscribe) { queue }
      channel = double(AMQP::Channel)
      exchange = double(AMQP::Exchange)
      channel.stub(:queue) { queue }
      channel.stub(:headers) { exchange }
      AMQP.stub(:channel) { channel }

      channel.should_receive(:queue).with("", {auto_delete: true, durable: false})
      queue.should_receive(:bind).with(exchange, {arguments: {"x-match" => "all", philotic_firehose: true}})
      queue.should_receive(:subscribe).with({})
      Philotic::Subscriber.subscribe_to_all_of(arguments: {philotic_firehose: true}) do |metadata, payload|
        true
      end
    end
  end

end
