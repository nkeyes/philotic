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

  describe 'publish' do
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
      subject.publish(event)
    end

  end

  describe 'raw_publish' do

    it 'should call exchange.publish with the right values' do
      Timecop.freeze
      exchange = double
      expect(subject.connection).to receive(:exchange).and_return(exchange)

      expect(subject.connection).to receive(:connect!)
      expect(subject.connection).to receive(:connected?).and_return(true)
      metadata = {
          routing_key:      nil,
          persistent:       true,
          mandatory:        true,
          content_type:     nil,
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
      subject.publish(event)
    end

    it 'should log an error when there is no connection' do


      expect(subject.connection).to receive(:connect!)
      expect(subject.connection).to receive(:connected?).once.and_return(false)

      expect(subject.logger).to receive(:error)
      subject.publish(event)
    end

  end
end
