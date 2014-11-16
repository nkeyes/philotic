require 'spec_helper'

module Philotic
  module Logging
    describe Logger do
      let(:logger) { Philotic::Logging::Logger.new(STDOUT) }
      let (:message) { 'Hey!' }
      specify do

        expect(Philotic::Publisher).to receive(:publish) do |event|
          expect(event.message).to eq message
          expect(event.severity).to eq Logger::INFO

        end
        logger.info message

      end
    end
  end
end