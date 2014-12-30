require 'spec_helper'

module Philotic
  module Logging
    describe Logger do
      let(:device) do
        fd = IO.sysopen('/dev/null', 'w')
        IO.new(fd, 'w')

      end
      let(:logger) { Philotic::Logging::Logger.new(device) }
      let(:message) { 'Hey!' }
      let(:error_message) { "These are not the droids you're looking for" }

      before do
        logger.connection = Philotic::Connection.new
      end
      specify do

        expect(logger.connection).to receive(:publish) do |event|
          expect(event.message).to eq message
          expect(event.severity).to eq Logger::INFO

        end

        expect(device).to receive(:write) do |log_message|
          expect(log_message).to match /#{message}/
        end
        logger.info message

      end

      it 'should accept a block' do
        expect(logger.connection).to receive(:publish) do |event|
          expect(event.message).to eq message
          expect(event.severity).to eq Logger::INFO

        end

        expect(device).to receive(:write) do |log_message|
          expect(log_message).to match /#{message}/
        end
        logger.info { message }
      end

      it "should not die if it can't log to RabbitMQ" do
        expect(logger.connection).to receive(:publish) do |event|
          raise error_message
        end

        expect(device).to receive(:write) do |log_message|
          expect(log_message).to match /#{message}/
        end

        expect(device).to receive(:write) do |log_message|
          expect(log_message).to match /#{error_message}/
        end
        logger.info message
      end

      it 'should behave not log if the severity is too low' do

        expect(logger.connection).not_to receive(:publish)

        expect(device).not_to receive(:write)
        logger.level = Logger::WARN
        logger.info message
      end
    end
  end
end