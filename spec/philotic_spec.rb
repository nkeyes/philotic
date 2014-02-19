require 'spec_helper'
require 'evented-spec'

describe Philotic do
  include EventedSpec::EMSpec
  include EventedSpec::SpecHelper

  default_timeout 10

  describe '.initialize_named_queue!' do

    let(:test_queues) do
      {
          app_live_feed: {
              exchange: 'philotic.headers.test_app.feed.live',
              options: {
                  arguments: {
                      :'x-dead-letter-exchange' => 'philotic.headers.test_app.feed.delayed',
                      :'x-message-ttl' => 600000 # ms
                  } },
              bindings:
                  [
                      {
                          philotic_product: 'test_app',
                          philotic_component: 'app_component',
                          :'x-match:' => 'all'
                      },
                  ],
          }
      }
    end
    it "should throw an error when ENV['INITIALIZE_NAMED_QUEUE'] is not set to 'true'" do
      ENV['INITIALIZE_NAMED_QUEUE'] = nil
      queue_name = test_queues.keys.first
      config = test_queues[queue_name]
      done do
        expect { Philotic.initialize_named_queue! queue_name, config }.to raise_error("ENV['INITIALIZE_NAMED_QUEUE'] must equal 'true' to run Philotic.initialize_named_queue!")
      end
    end

it 'should set up the queue with the right parameters' do
  ENV['INITIALIZE_NAMED_QUEUE'] = 'true'

  test_queues.each_pair do |queue_name, config|

    queue_options = Philotic::DEFAULT_NAMED_QUEUE_OPTIONS.dup
    queue_options.merge!(config[:options] || {})

    channel_double = double(AMQP::Channel)
    queue_double = double(AMQP::Queue)
    exchange_double = double(AMQP::Exchange)

    expect(Philotic).to receive(:connect!).and_yield.exactly(2).times
    expect(AMQP).to receive(:channel).and_return(channel_double).exactly(2).times
    expect(channel_double).to receive(:queue).with(queue_name, queue_options).and_yield(queue_double).exactly(2).times
    expect(queue_double).to receive(:delete).and_yield
    expect(Philotic::Connection).to receive(:close).and_yield
    expect(channel_double).to receive(:headers).with(config[:exchange], durable: true) { exchange_double }
    expect(AMQP).to receive(:channel) { channel_double }
    expect(queue_double).to receive(:name) { queue_name }

    config[:bindings].each do |arguments|
      expect(queue_double).to receive(:bind).with(exchange_double, { arguments: arguments })
      Philotic.initialize_named_queue! queue_name, config
    end

    done((test_queues.keys.length + 1) * 0.1) do

    end
  end
end
  end
end
