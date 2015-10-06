require 'spec_helper'

require 'philotic/dummy_message'
require 'philotic/connection'
require 'philotic/constants'
require 'philotic/subscriber'

describe Philotic::Subscriber do


  describe '#subscription_callback' do

    subject { Philotic::Connection.new.subscriber }
    let(:subscribe_callback) do
      Proc.new do |message|
        message
      end
    end

    let(:delivery_info) { double }
    let(:metadata) { {headers: {header_1: 'foo', philotic_serializations: Philotic.config.serializations}} }
    let(:payload) { {message: 'body'} }

    it 'hydrates received messages' do
      message = subject.subscription_callback(&subscribe_callback).call(delivery_info, metadata, payload.to_json)
      expect(message).to be_a Philotic::Message
      expect(message.headers).to include(metadata[:headers])
      expect(message.payload).to eq payload
    end
  end

  describe '#subscribe' do
    let(:subscription) { 'some_queue' }
    subject { Philotic::Connection.new.subscriber }
    context 'when options is a string' do
      it 'binds to a queue defined by the options' do
        channel = double
        queue   = double

        metadata = double
        message  = double

        callback = lambda { |metadata, message|}

        expect(subject.connection).to receive(:connect!)

        expect(subject.connection).to receive(:channel).and_return(channel).twice
        expect(channel).to receive(:prefetch).with(subject.connection.config.prefetch_count)
        expect(channel).to receive(:queue).and_return(queue)

        expect(queue).not_to receive(:bind)
        expect(queue).to receive(:subscribe).with({})
        expect(subject).to receive(:subscription_callback).and_yield(metadata, message)
        expect(callback).to receive(:call).with(metadata, message)

        subject.subscribe(subscription, &callback)
      end
    end

    context 'when options is not a string' do
      let(:subscription) do
        {
          firehose: true
        }
      end
      it 'binds to a queue defined by the options' do

        exchange = double
        channel  = double
        queue    = double

        metadata = double
        message  = double

        callback = lambda { |metadata, payload|}

        expect(subject.connection).to receive(:connect!)

        expect(subject.connection).to receive(:exchange).and_return(exchange)
        expect(subject.connection).to receive(:channel).and_return(channel).twice
        expect(channel).to receive(:prefetch).with(subject.connection.config.prefetch_count)
        expect(channel).to receive(:queue).and_return(queue)

        expect(queue).to receive(:bind).with(exchange, hash_including(arguments: subscription))
        expect(queue).to receive(:subscribe).with({})
        expect(subject).to receive(:subscription_callback).and_yield(metadata, message)
        expect(callback).to receive(:call).with(metadata, message)

        subject.subscribe(subscription, &callback)
      end
    end
  end

  describe '#subscribe_to_any' do
    let(:headers) do
      {
        header1: 'h1',
        header2: 'h2',
        header3: 'h3',
      }
    end
    subject { Philotic::Connection.new.subscriber }

    specify do
      expect(subject).to receive(:subscribe).with(headers.merge(:'x-match' => :any))
      subject.subscribe_to_any(headers) {}
    end
  end

  describe '#acknowledge' do
    let(:channel) { double }
    let(:delivery_tag) { double }
    let(:delivery_info) { double }
    let(:message) { Class.new(Philotic::Message).new }
    subject { Philotic::Connection.new.subscriber }

    specify do
      expect(subject.connection).to receive(:channel).and_return(channel)
      expect(message).to receive(:delivery_info).and_return(delivery_info)
      expect(delivery_info).to receive(:delivery_tag).and_return(delivery_tag)
      expect(channel).to receive(:acknowledge).with(delivery_tag, false)
      subject.acknowledge(message)
    end
  end

  describe '#reject' do
    let(:channel) { double }
    let(:delivery_tag) { double }
    let(:delivery_info) { double }
    let(:message) { Class.new(Philotic::Message).new }
    subject { Philotic::Connection.new.subscriber }

    specify do
      expect(subject.connection).to receive(:channel).and_return(channel)
      expect(message).to receive(:delivery_info).and_return(delivery_info)
      expect(delivery_info).to receive(:delivery_tag).and_return(delivery_tag)
      expect(channel).to receive(:reject).with(delivery_tag, true)
      subject.reject(message)
    end
  end
end
