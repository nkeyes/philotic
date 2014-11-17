require 'spec_helper'

describe Philotic do

  describe '.initialize_named_queue!' do

    let(:test_queues) do
      {
          app_live_feed: {
              exchange: 'philotic.headers.test_app.feed.live',
              options:  {
                  arguments: {
                      :'x-dead-letter-exchange' => 'philotic.headers.test_app.feed.delayed',
                      :'x-message-ttl'          => 600000 # ms
                  }},
              bindings:
                        [
                            {
                                philotic_product:   'test_app',
                                philotic_component: 'app_component',
                                :'x-match:'         => 'all'
                            },
                        ],
          }
      }
    end
    it "should throw an error when ENV['INITIALIZE_NAMED_QUEUE'] is not set to 'true'" do
      ENV['INITIALIZE_NAMED_QUEUE'] = nil
      queue_name                    = test_queues.keys.first
      config                        = test_queues[queue_name]
      expect(Philotic).to receive(:connect!)
      expect { Philotic.initialize_named_queue! queue_name, config }.to raise_error("ENV['INITIALIZE_NAMED_QUEUE'] must equal 'true' to run Philotic.initialize_named_queue!")

    end

    it 'should set up the queue with the right parameters' do
      ENV['INITIALIZE_NAMED_QUEUE'] = 'true'

      test_queues.each_pair do |queue_name, config|

        queue_options = Philotic::DEFAULT_NAMED_QUEUE_OPTIONS.dup
        queue_options.merge!(config[:options] || {})

        channel    = double
        queue      = double
        exchange   = double
        connection = double

        expect(Philotic).to receive(:connect!)
        expect(Philotic::Connection).to receive(:connection).and_return(connection)
        expect(connection).to receive(:queue_exists?)
        expect(Philotic::Connection).to receive(:channel).and_return(channel).exactly(2).times
        expect(channel).to receive(:queue).with(queue_name, queue_options).and_return(queue)
        expect(channel).to receive(:headers).with(config[:exchange], durable: true) { exchange }
        expect(queue).to receive(:name).and_return(queue_name).exactly(2).times

        config[:bindings].each do |arguments|
          expect(queue).to receive(:bind).with(exchange, {arguments: arguments})
          Philotic.initialize_named_queue! queue_name, config
        end


      end
    end
  end
end
