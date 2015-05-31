require 'spec_helper'

module Philotic
  module Logging
    describe Logger do
      let(:device) do
        fd = IO.sysopen('/dev/null', 'w')
        IO.new(fd, 'w')

      end
      let(:logger) { Philotic::Logging::Logger.new(device) }
      let(:expected_message) { 'Hey!' }
      let(:error_message) { "These are not the droids you're looking for" }

      before do
        logger.connection = Philotic::Connection.new
      end
      specify do

        expect(logger.connection).to receive(:publish) do |message|
          expect(message.message).to eq expected_message
          expect(message.severity).to eq Logger::INFO

        end

        expect(device).to receive(:write) do |log_message|
          expect(log_message).to match /#{expected_message}/
        end
        logger.info expected_message

      end

      it 'should accept a block' do
        expect(logger.connection).to receive(:publish) do |message|
          expect(message.message).to eq expected_message
          expect(message.severity).to eq Logger::INFO

        end

        expect(device).to receive(:write) do |log_message|
          expect(log_message).to match /#{expected_message}/
        end
        logger.info { expected_message }
      end

      it "should not die if it can't log to RabbitMQ" do
        expect(logger.connection).to receive(:publish) do |message|
          raise error_message
        end

        expect(device).to receive(:write) do |log_message|
          expect(log_message).to match /#{expected_message}/
        end

        expect(device).to receive(:write) do |log_message|
          expect(log_message).to match /#{error_message}/
        end
        logger.info expected_message
      end

      it 'should behave not log if the severity is too low' do

        expect(logger.connection).not_to receive(:publish)

        expect(device).not_to receive(:write)
        logger.level = Logger::WARN
        logger.info expected_message
      end
    end
  end
end