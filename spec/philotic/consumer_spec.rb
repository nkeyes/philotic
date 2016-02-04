require 'spec_helper'

require 'philotic/consumer'
require 'philotic/connection'
require 'philotic/subscriber'


describe Philotic::Consumer do
  let(:named_queue) { :named_queue }
  let(:anonymous_subscription) { {
    header_1: :value_1,
    header_2: :value_2,
    header_3: :value_3,
  } }
  subject { Class.new Philotic::Consumer }

  describe '.subscribe_to' do
    it 'sets the class variable @subscription' do

      expect(subject.subscription).not_to be

      subject.subscribe_to named_queue
      expect(subject.subscription).to eq named_queue

      subject.subscribe_to anonymous_subscription
      expect(subject.subscription).to eq anonymous_subscription
    end
  end

  describe '.manually_acknowledge' do
    it 'sets the class variable @manually_acknowledge' do
      expect(subject).not_to be_manually_acknowledge
      subject.manually_acknowledge
      expect(subject).to be_manually_acknowledge
    end
  end

  describe '.auto_acknowledge' do
    it 'sets the class variable @auto_acknowledge' do
      expect(subject).not_to be_auto_acknowledge
      subject.auto_acknowledge
      expect(subject).to be_auto_acknowledge
    end
  end

  describe '.exclusive' do
    it 'sets the class variable @exclusive' do
      expect(subject).not_to be_exclusive
      subject.exclusive
      expect(subject).to be_exclusive
    end
  end

  describe '.requeueable_errors' do
    it 'maintains a set of requeueable errors' do
      expect(subject.requeueable_errors).to be_empty
      expect(subject.requeueable_errors(RuntimeError).size).to be 1
      expect(subject.requeueable_errors).to include(RuntimeError)

      expect(subject.requeueable_errors(RuntimeError, NotImplementedError).size).to be 2
      expect(subject.requeueable_errors).to include(NotImplementedError)


      # don't allow dupes
      expect(subject.requeueable_errors(RuntimeError, NotImplementedError).size).to be 2

    end
  end

  describe '.subscribe' do
    let (:connection) { instance_double Philotic::Connection }
    let (:consumer_instance) { instance_double subject }
    it 'proxies to, and returns, a new instance' do
      expect(Philotic).to receive(:connection).and_return(connection)
      expect(subject).to receive(:new).and_return(consumer_instance)
      expect(consumer_instance).to receive(:subscribe)

      expect(subject.subscribe).to be consumer_instance
    end
  end

  describe '#subscription_options' do
    it 'returns a hash with the exclusive and manual_ack options' do
      expect(subject.subscription_options).to match({manual_ack: false, exclusive: false})

      subject.auto_acknowledge
      expect(subject.subscription_options).to match({manual_ack: true, exclusive: false})

      subject.instance_variable_set(:@auto_acknowledge, nil)
      expect(subject.subscription_options).to match({manual_ack: false, exclusive: false})

      subject.manually_acknowledge
      expect(subject.subscription_options).to match({manual_ack: true, exclusive: false})

      subject.exclusive
      expect(subject.subscription_options).to match({manual_ack: true, exclusive: true})
    end
  end

  describe '#subscribe' do
    it 'proxies to Philotic::Subscriber#subscribe' do
      subject.subscribe_to named_queue
      subject.auto_acknowledge
      subject.exclusive

      expect_any_instance_of(Philotic::Subscriber).to receive(:subscribe).with(named_queue, manual_ack: true, exclusive: true)

      subject.subscribe
    end
  end

  describe '#consume' do
    subject { (Class.new(Philotic::Consumer)).new(nil) }

    it 'raises an error unless the inheriting class redefines it' do
      expect { subject.consume(nil) }.to raise_error(NotImplementedError)

      subject.define_singleton_method :consume do |message|
        # no op
      end

      expect { subject.consume(nil) }.to_not raise_error
    end
  end

  describe '#_consume' do
    subject { (Class.new(Philotic::Consumer)).new(nil) }
    let(:message) { instance_double Philotic::Message }

    it 'proxies to #consume  when @auto_acknowledge is falsey' do
      expect(subject).to receive(:consume).with(message)

      subject.send(:_consume, message)
    end

    it 'proxies to #_auto_ack_consume when @auto_acknowledge is truthy' do
      expect(subject).to receive(:_auto_ack_consume).with(message)

      subject.class.auto_acknowledge
      subject.send(:_consume, message)
    end

  end

  describe '#_auto_ack_consume' do
    subject { (Class.new(Philotic::Consumer)).new(nil) }
    let(:message) { instance_double Philotic::Message }

    it 'acknowledges messages when @ack_messages is set' do
      subject.define_singleton_method :consume do |message|
        # no op
      end

      expect(subject).to receive(:acknowledge).with(message)

      subject.send(:_auto_ack_consume, message)
      end

    it 'requeues messages when @ack_messages is set and a requeueable error is thrown' do
      subject.class.requeueable_errors(RuntimeError)

      subject.define_singleton_method :consume do |message|
        raise RuntimeError.new 'oops'
      end

      expect(subject).to receive(:reject).with(message, true)

      subject.send(:_auto_ack_consume, message)
    end

    it 'rejects messages when @ack_messages is set and a non-requeueable error is thrown' do
      subject.define_singleton_method :consume do |message|
        raise RuntimeError.new 'oops'
      end

      expect(subject).to receive(:reject).with(message, false)

      subject.send(:_auto_ack_consume, message)
    end
  end
end
