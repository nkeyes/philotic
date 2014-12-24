require 'spec_helper'

describe Philotic::Connection do


  describe '#connect!' do
    subject { Philotic::Connection.new }
    context 'not connected' do
      context 'success' do
        specify do
          expect(subject).to receive(:connected?).and_return(false, true)
          expect(subject).to receive(:start_connection!)
          expect(subject).to receive(:set_exchange_return_handler!)

          subject.connect!
        end
      end

      context 'failure' do
        specify do
          expect(subject).to receive(:connected?).and_return(false, false)
          expect(subject).to receive(:start_connection!)
          expect(subject).not_to receive(:set_exchange_return_handler!)
          expect(subject.logger).to receive(:error)

          subject.connect!
        end
      end
    end

    context 'not connected' do
      context 'success' do
        specify do
          expect(subject).to receive(:connected?).and_return(true)
          expect(subject).not_to receive(:start_connection!)
          expect(subject).not_to receive(:set_exchange_return_handler!)

          subject.connect!
        end
      end
    end
  end

  describe '#start_connection!' do
    let(:connection) { double }
    let(:connection_error) {Bunny::TCPConnectionFailed.new 'connection failed', 'localhost', '5672'}
    subject { Philotic::Connection.new }
    specify do
      expect(Bunny).to receive(:new).with(subject.config.rabbit_url, subject.connection_settings).and_return(connection)
      expect(connection).to receive(:start)

      subject.start_connection!
    end

    it 'should retry connecting' do
      expect(Bunny).to receive(:new) do
        raise connection_error
      end.exactly(subject.config.connection_retries + 1).times

      expect { subject.start_connection! }.to raise_error(Philotic::Connection::TCPConnectionFailed)
    end

  end

  describe '#close' do
    let(:connection) { double }
    subject { Philotic::Connection.new }
    specify do
      allow(subject).to receive(:connection).and_return(connection)
      expect(connection).to receive(:connected?).and_return(true)
      expect(connection).to receive(:close)
      expect(subject.instance_variable_get(:@channel)).to eq(nil)
      expect(subject.instance_variable_get(:@exchange)).to eq(nil)
      subject.close
    end
  end

  describe '#initialize_named_queue!' do
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
    subject { Philotic::Connection.new }
    
    it 'should throw an error when Philotic::Config.initialize_named_queues is falsey' do
      allow(subject.config).to receive(:initialize_named_queues).and_return(nil)
      queue_name = test_queues.keys.first
      config     = test_queues[queue_name]
      expect(subject).not_to receive(:connect!)
      expect { subject.initialize_named_queue! queue_name, config }.to raise_error

    end

    it 'should log a warning when Philotic::Config.delete_existing_queues is falsey and the queue already exists' do
      allow(subject.config).to receive(:initialize_named_queues).and_return(true)
      allow(subject.config).to receive(:delete_existing_queues).and_return(nil)

      test_queues.each_pair do |queue_name, config|

        connection = double

        expect(subject).to receive(:connect!)
        expect(subject).to receive(:connection).and_return(connection)
        expect(connection).to receive(:queue_exists?).and_return(true)

        expect(subject.logger).to receive(:warn)

        subject.initialize_named_queue! queue_name, config
      end
    end

    it 'should delete the queue first when Philotic::Config.delete_existing_queues is truthy and the queue already exists' do
      allow(subject.config).to receive(:initialize_named_queues).and_return(true)
      allow(subject.config).to receive(:delete_existing_queues).and_return(true)

      test_queues.each_pair do |queue_name, config|

        queue_options = Philotic::DEFAULT_NAMED_QUEUE_OPTIONS.dup
        queue_options.merge!(config[:options] || {})

        channel    = double
        queue      = double
        exchange   = double
        connection = double

        expect(subject).to receive(:connect!)
        expect(subject).to receive(:connection).and_return(connection)
        expect(connection).to receive(:queue_exists?).and_return(true)
        expect(subject).to receive(:channel).and_return(channel).exactly(3).times
        expect(channel).to receive(:queue).with(queue_name, {passive: true}).and_return(queue)
        expect(queue).to receive(:delete)
        expect(channel).to receive(:queue).with(queue_name, queue_options).and_return(queue)
        expect(channel).to receive(:headers).with(config[:exchange], durable: true) { exchange }
        expect(queue).to receive(:name).and_return(queue_name).exactly(2).times

        config[:bindings].each do |arguments|
          expect(queue).to receive(:bind).with(exchange, {arguments: arguments})
        end
        subject.initialize_named_queue! queue_name, config
      end
    end
  end
end