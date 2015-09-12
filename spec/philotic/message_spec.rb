require 'spec_helper'

require 'philotic/message'

# create 'deep' inheritance to test self.inherited
class TestEventParent < Philotic::Message
end
class TestEvent < TestEventParent
  attr_routable :routable_attr
  attr_payload :payload_attr
end

describe Philotic::Message do

  it 'is not instantiable' do
    expect { Philotic::Message.new }.to raise_error(Philotic::Message::NotInstantiableError)
  end

  let(:message) { TestEvent.new }
  subject { message }

  %w[
      attr_routable_accessors
      attr_routable
      attr_payload_accessors
      attr_payload
  ].each do |method_name|
    specify { expect(subject.class.methods).to include method_name.to_sym }
  end

  it 'should have proper headers' do
    expect(subject.headers).to include({routable_attr: nil})
  end

  it 'should have proper payload' do
    expect(subject.payload).to eq({payload_attr: nil})
  end

  it 'should have proper attributes' do
    expect(subject.attributes).to include({routable_attr: nil, payload_attr: nil})
  end

  it 'should have empty metadata, other than timestamp' do
    expect(subject.metadata.keys).to eq([:timestamp])
  end

  Philotic::Message.methods.sort.each do |method_name|
    specify { expect(subject.class.methods).to include method_name.to_sym }
  end

  Philotic::MESSAGE_OPTIONS.each do |method_name|
    specify { expect(subject.methods).to include method_name.to_sym }
    specify { expect(subject.methods).to include "#{method_name}=".to_sym }
  end

  Philotic::PHILOTIC_HEADERS.each do |method_name|
    specify { expect(subject.methods).to include method_name.to_sym }
    specify { expect(subject.methods).to include "#{method_name}=".to_sym }
  end

  describe 'metadata' do

    context 'overriding a value with metadata=' do
      before do
        subject.metadata = {mandatory: false}
      end
      it 'should work' do
        expect(subject.metadata).to include({mandatory: false})
      end
    end

    it 'should have a timestamp' do
      Timecop.freeze
      expect(subject.metadata).to eq(timestamp: Time.now.to_i)
    end

    it 'should reflect changes in the message properties' do
      expect(subject.metadata[:app_id]).to eq nil
      subject.app_id = 'ANSIBLE'
      expect(subject.metadata[:app_id]).to eq 'ANSIBLE'
    end
  end
  describe 'headers' do
    it 'should include :philotic_product' do
      expect(subject.headers.keys).to include :philotic_product
    end
  end

  describe 'generic messages' do
    let(:headers) do
      {
        header1: 'h1',
        header2: 'h2',
        header3: 'h3',
      }
    end

    let(:payloads) do
      {
        payload1: 'h1',
        payload2: 'h2',
        payload3: 'h3',
      }
    end

    describe 'publishing messages' do
      let(:message_1_headers) { {message_1_header_1: 1, message_1_header_2: 2} }
      let(:message_1_payload) { {message_1_payload_1: 1, message_1_payload_2: 2} }

      let(:message_2_headers) { {message_2_header_1: 1, message_2_header_2: 2} }
      let(:message_2_payload) { {message_2_payload_1: 1, message_2_payload_2: 2} }

      it 'builds the proper routable accessors' do
        expect(Philotic.connection).to receive(:publish) do |message|
          expect(message.class.attr_routable_accessors).to include(*message_1_headers.keys)
        end
        Philotic::Message.publish message_1_headers, message_1_payload
      end

      it 'builds the proper payload accessors' do
        expect(Philotic.connection).to receive(:publish) do |message|
          expect(message.class.attr_payload_accessors).to include(*message_1_payload.keys)
        end
        Philotic::Message.publish message_1_headers, message_1_payload
      end

      it 'builds the proper headers' do
        expect(Philotic.connection).to receive(:publish) do |message|
          expect(message.headers).to include(message_1_headers)
        end
        Philotic::Message.publish message_1_headers, message_1_payload
      end

      it 'builds the proper payload' do
        expect(Philotic.connection).to receive(:publish) do |message|
          expect(message.payload).to include(message_1_payload)
        end
        Philotic::Message.publish message_1_headers, message_1_payload
      end

      describe 'in succession' do
        it 'builds the proper routable accessors on succesive calls' do
          allow(Philotic.connection).to receive(:publish)
          Philotic::Message.publish message_1_headers, message_1_payload

          expect(Philotic.connection).to receive(:publish) do |message|
            expect(message.class.attr_routable_accessors).not_to include(*message_1_headers.keys)
            expect(message.class.attr_routable_accessors).to include(*message_2_headers.keys)
          end

          Philotic::Message.publish message_2_headers, message_2_payload

        end

        it 'builds the proper payload accessors on succesive calls' do
          allow(Philotic.connection).to receive(:publish)
          Philotic::Message.publish message_1_headers, message_1_payload

          expect(Philotic.connection).to receive(:publish) do |message|
            expect(message.class.attr_payload_accessors).not_to include(*message_1_payload.keys)
            expect(message.class.attr_payload_accessors).to include(*message_2_payload.keys)
          end

          Philotic::Message.publish message_2_headers, message_2_payload

        end

        it 'builds the proper headers on succesive calls' do
          allow(Philotic.connection).to receive(:publish)
          Philotic::Message.publish message_1_headers, message_1_payload

          expect(Philotic.connection).to receive(:publish) do |message|
            expect(message.headers).not_to include(message_1_headers)
            expect(message.headers).to include(message_2_headers)
          end

          Philotic::Message.publish message_2_headers, message_2_payload

        end

        it 'builds the proper payload on succesive calls' do
          allow(Philotic.connection).to receive(:publish)
          Philotic::Message.publish message_1_headers, message_1_payload

          expect(Philotic.connection).to receive(:publish) do |message|
            expect(message.payload).not_to include(message_1_payload)
            expect(message.payload).to include(message_2_payload)
          end

          Philotic::Message.publish message_2_headers, message_2_payload

        end
      end
    end
  end

  describe '#publish' do
    subject { Class.new(Philotic::Message).new }
    specify do
      expect(subject.connection).to receive(:publish).with(subject)

      subject.publish
    end
  end

  describe '.publish' do
    let (:connection) { double }
    let(:headers) do
      {
        header1: 'h1',
        header2: 'h2',
        header3: 'h3',
      }
    end

    let(:payloads) do
      {
        payload1: 'h1',
        payload2: 'h2',
        payload3: 'h3',
      }
    end
    subject { Philotic::Message }
    specify do
      expect_any_instance_of(Philotic::Message).to receive(:connection).and_return(connection)
      expect(connection).to receive(:publish) do |message|
        expect(message.headers).to include(headers)
        expect(message.payload).to eq payloads
      end

      subject.publish(headers, payloads)
    end

  end
end