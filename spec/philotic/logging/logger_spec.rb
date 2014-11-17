require 'spec_helper'

module Philotic
  module Logging
    describe Logger do
      let (:device) { double }
      let(:logger) { Philotic::Logging::Logger.new(device) }
      let (:message) { 'Hey!' }
      specify do

        expect(Philotic::Publisher).to receive(:publish) do |event|
          expect(event.message).to eq message
          expect(event.severity).to eq Logger::INFO

        end
        expect(device).to receive(:respond_to?).with(:write).and_return(true)
        expect(device).to receive(:respond_to?).with(:close).and_return(true)
        expect(device).to receive(:write) do |log_message|
          expect(log_message).to match /#{message}/
        end
        logger.info message

      end
    end
  end
end