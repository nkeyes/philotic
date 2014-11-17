require 'spec_helper'
require 'philotic/dummy_event'
require 'philotic/constants'

describe Philotic::Subscriber do


  describe '.subscribe' do
    let(:subscription) { 'some_queue' }
    context 'when options is a string' do
      it 'binds to a queue defined by the options' do

        exchange = double
        channel  = double
        queue    = double

        metadata = double
        message  = double

        callback = lambda { |metadata, message|}

        expect(Philotic).to receive(:connect!)

        expect(Philotic::Connection).to receive(:exchange).and_return(exchange)
        expect(Philotic::Connection).to receive(:channel).and_return(channel)
        expect(channel).to receive(:queue).and_return(queue)

        expect(queue).not_to receive(:bind)
        expect(queue).to receive(:subscribe).with({})
        expect(Philotic::Subscriber).to receive(:subscription_callback).and_yield(metadata, message)
        expect(callback).to receive(:call).with(metadata, message)

        Philotic::Subscriber.subscribe(subscription, &callback)
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

        expect(Philotic).to receive(:connect!)

        expect(Philotic::Connection).to receive(:exchange).and_return(exchange)
        expect(Philotic::Connection).to receive(:channel).and_return(channel)
        expect(channel).to receive(:queue).and_return(queue)

        expect(queue).to receive(:bind).with(exchange, hash_including(arguments: subscription))
        expect(queue).to receive(:subscribe).with({})
        expect(Philotic::Subscriber).to receive(:subscription_callback).and_yield(metadata, message)
        expect(callback).to receive(:call).with(metadata, message)

        Philotic::Subscriber.subscribe(subscription, &callback)
      end
    end
  end

  describe '.subscribe_to_any' do
    let(:headers) do
      {
          header1: 'h1',
          header2: 'h2',
          header3: 'h3',
      }
    end
    specify do
      expect(Philotic::Subscriber).to receive(:subscribe).with(headers.merge(:'x-match' => :any))
      Philotic::Subscriber.subscribe_to_any(headers) {}
    end
  end

  describe '.acknowledge' do
    let(:channel) { double }
    let(:delivery_tag) { double }
    let(:delivery_info) { double }
    let(:message) { {delivery_info: delivery_info} }

    specify do
      expect(Philotic::Connection).to receive(:channel).and_return(channel)
      expect(delivery_info).to receive(:delivery_tag).and_return(delivery_tag)
      expect(channel).to receive(:acknowledge).with(delivery_tag, false)
      Philotic::Subscriber.acknowledge(message)
    end
  end

  describe '.reject' do
    let(:channel) { double }
    let(:delivery_tag) { double }
    let(:delivery_info) { double }
    let(:message) { {delivery_info: delivery_info} }

    specify do
      expect(Philotic::Connection).to receive(:channel).and_return(channel)
      expect(delivery_info).to receive(:delivery_tag).and_return(delivery_tag)
      expect(channel).to receive(:reject).with(delivery_tag, true)
      Philotic::Subscriber.reject(message)
    end
  end
end
