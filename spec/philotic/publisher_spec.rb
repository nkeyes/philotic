require 'spec_helper'
require 'philotic/dummy_event'
require 'philotic/connection'
require 'philotic/publisher'

describe Philotic::Publisher do
  let(:event) do
    event           = Philotic::DummyEvent.new
    event.subject   = 'Hello'
    event.message   = 'How are you?'
    event.gender    = :M
    event.available = true

    event
  end
  let(:publisher) { Philotic::Connection.new.publisher }
  subject { publisher }

  describe '#publish' do
    let(:publish_error) { StandardError.new 'publish error' }
    it 'should call _publish with the right values' do
      Timecop.freeze
      expect(subject).to receive(:_publish).with(
                             {
                                 subject: 'Hello',
                                 message: 'How are you?'
                             },
                             {
                                 headers:   {
                                     philotic_firehose:   true,
                                     philotic_product:    nil,
                                     philotic_component:  nil,
                                     philotic_event_type: nil,
                                     gender:              :M,
                                     available:           true
                                 },
                                 timestamp: Time.now.to_i
                             }
                         )
      expect(event).to_not be_published
      subject.publish(event)
      expect(event).to_not be_published # not connected
    end

    it 'should fail gracefully' do
      expect(subject).to receive(:_publish) do
        raise publish_error
      end

      expect(subject.logger).to receive(:error).with(publish_error.message)
      expect(event).to_not be_published
      subject.publish(event)
      expect(event).to_not be_published
      expect(event.publish_error).to eq publish_error

    end

    context 'when publishing is disabled' do
      before do
        subject.config.disable_publish = true
      end
      it 'should log a warning' do
        expect(subject).to receive(:log_event_published)

        expect(event).to_not be_published
        subject.publish(event)
        expect(event).to_not be_published
      end
    end
  end

  describe '#raw_publish' do

    it 'should call exchange.publish with the right values' do
      Timecop.freeze
      exchange = double
      expect(subject.connection).to receive(:exchange).and_return(exchange)

      expect(subject.connection).to receive(:connect!)
      expect(subject.connection).to receive(:connected?).and_return(true)
      metadata = {
          routing_key:      nil,
          persistent:       false,
          immediate:        false,
          mandatory:        false,
          content_type:     'application/json',
          content_encoding: nil,
          priority:         nil,
          message_id:       nil,
          correlation_id:   nil,
          reply_to:         nil,
          type:             nil,
          user_id:          nil,
          app_id:           nil,
          expiration:       nil,
          headers:          {
              philotic_firehose:   true,
              philotic_product:    nil,
              philotic_component:  nil,
              philotic_event_type: nil,
              gender:              :M,
              available:           true
          },
          timestamp:        Time.now.to_i
      }


      expect(exchange).to receive(:publish).with(
                              {
                                  subject: 'Hello',
                                  message: 'How are you?'
                              }.to_json,
                              metadata
                          )
      expect(event).to_not be_published
      subject.publish(event)
      expect(event).to be_published
    end

    it 'should log an error when there is no connection' do

      expect(subject.connection).to receive(:connect!)
      expect(subject.connection).to receive(:connected?).once.and_return(false)

      expect(subject.logger).to receive(:error)
      expect(event).to_not be_published
      subject.publish(event)
      expect(event).to_not be_published
    end

  end

  describe '#normalize_payload_times' do
    let(:responds_to_utc) { double }
    let(:responds_to_to_utc) { double }
    let (:payload) { {utc: responds_to_utc, to_utc: responds_to_to_utc} }
    let(:normalized_utc) { 1 }
    let(:normalized_to_utc) { 2 }
    let (:normalized_payload) { {utc: normalized_utc, to_utc: normalized_to_utc} }
    it 'should call .utc on values that respond to it' do
      expect(responds_to_utc).to receive(:respond_to?).with(:utc).and_return(true)
      expect(responds_to_utc).to receive(:utc).and_return(normalized_utc)

      expect(responds_to_to_utc).to receive(:respond_to?).with(:utc).and_return(false)
      expect(responds_to_to_utc).to receive(:respond_to?).with(:to_utc).and_return(true)
      expect(responds_to_to_utc).to receive(:to_utc).and_return(normalized_to_utc)

      subject.normalize_payload_times payload

      expect(payload).to eq normalized_payload

    end
  end
end
