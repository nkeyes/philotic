require 'spec_helper'
require 'philotic/dummy_event'

describe Philotic::Publisher do
  before(:each) do
    @event           = Philotic::DummyEvent.new
    @event.subject   = 'Hello'
    @event.message   = 'How are you?'
    @event.gender    = :M
    @event.available = true
  end
  let(:publisher) { Philotic::Publisher }
  subject { publisher }

  describe 'config' do
    it 'should return the Philotic::Config singleton' do
      expect(subject.config).to eq Philotic::Config
    end
  end


  describe 'publish' do
    it 'should call _publish with the right values' do
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
      subject.publish(@event)
    end

  end

  describe 'raw_publish' do

    it 'should call exchange.publish with the right values' do
      exchange = double
      expect(Philotic::Connection).to receive(:exchange).and_return(exchange)

      expect(Philotic).to receive(:connect!)
      expect(Philotic::Connection).to receive(:connected?).and_return(true)

      expect(exchange).to receive(:publish).with(
                              {
                                  subject: 'Hello',
                                  message: 'How are you?'
                              }.to_json,
                              {
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
                          )
      subject.publish(@event)
    end

    it 'should log an error when there is no connection' do


      expect(Philotic).to receive(:connect!)
      expect(Philotic::Connection).to receive(:connected?).once.and_return(false)

      expect(Philotic.logger).to receive(:error)
      subject.publish(@event)
    end

  end
end
