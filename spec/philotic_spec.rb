require 'spec_helper'
require 'evented-spec'

describe Philotic do
  include EventedSpec::EMSpec
  include EventedSpec::SpecHelper

  default_timeout 10

  describe '.initialize_named_queue!' do

    after(:all) do
      test_queues.each_pair do |queue_name, config|
        Philotic.delete_queue(queue_name, config)
      end
    end

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
        config[:bindings].each do |arguments|
          expect_any_instance_of(AMQP::Queue).to receive(:bind).with(instance_of(AMQP::Exchange), { arguments: arguments })
          Philotic.initialize_named_queue! queue_name, config
        end

        done((test_queues.keys.length + 1) * 0.1) do

        end
      end
    end
  end
end
