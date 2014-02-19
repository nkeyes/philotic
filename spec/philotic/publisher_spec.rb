require 'spec_helper'
require 'philotic/dummy_event'

describe Philotic::Publisher do
  before(:each) do
    @event = Philotic::DummyEvent.new
    @event.subject = "Hello"
    @event.message = "How are you?"
    @event.gender = :M
    @event.available = true
  end
  let(:publisher) { Philotic::Publisher }
  subject { publisher }

  describe "config" do
    it "should return the Philotic::Config singleton" do
      subject.config.should == Philotic::Config
    end
  end

  describe "exchange" do
    #TODO make sure rabbit is running for CI to run this
    xit "should return an instance of AMQP::Exchange" do
      subject.exchange.should be_a AMQP::Exchange
    end
  end

  describe "publish" do
    it "should call raw_publish with the right values" do
      Timecop.freeze
      subject.should_receive(:raw_publish).with(
          {
              subject: 'Hello',
              message: "How are you?"
          },
          {
              headers: {
                  philotic_firehose: true,
                  philotic_product: nil,
                  philotic_component: nil,
                  philotic_event_type: nil,
                  gender: :M,
                  available: true
              },
              timestamp: Time.now.to_i
          }
      )
      subject.publish(@event)
    end

  end

  describe "raw_publish" do

    xit "should call exchange.publish with the right values" do
      Timecop.freeze
      Philotic::Connection.instance.should_receive(:connected?).and_return { true }

      AMQP::Exchange.any_instance.should_receive(:publish).with(
          {
              subject: 'Hello',
              message: "How are you?"
          }.to_json,
          {
              routing_key: nil,
              persistent: true,
              mandatory: true,
              content_type: nil,
              content_encoding: nil,
              priority: nil,
              message_id: nil,
              correlation_id: nil,
              reply_to: nil,
              type: nil,
              user_id: nil,
              app_id: nil,
              expiration: nil,
              headers: {
                  philotic_firehose: true,
                  philotic_product: nil,
                  philotic_component: nil,
                  philotic_event_type: nil,
                  gender: :M,
                  available: true
              },
              timestamp: Time.now.to_i
          }
      )
      subject.publish(@event)
    end

    xit "should log an error when there is no connection" do

      4.times do
        Philotic::Connection.instance.should_receive(:connected?).and_return { false }
      end
      Philotic.logger.should_receive(:error)
      subject.publish(@event)
    end

  end
end
