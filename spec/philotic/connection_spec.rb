require 'spec_helper'

describe Philotic::Connection do

  describe '.config' do
    its(:config) { should eq Philotic::Config }
  end

  describe '.connect!' do
    context 'not connected' do
      context 'success' do
        specify do
          expect(subject).to receive(:connected?).and_return(false, true)
          expect(subject).to receive(:start_connection!)
          expect(subject).to receive(:set_exchange_return_handler!)

          subject.connect!

        end
      end

      context 'failure' do
        specify do
          expect(subject).to receive(:connected?).and_return(false, false)
          expect(subject).to receive(:start_connection!)
          expect(subject).not_to receive(:set_exchange_return_handler!)
          expect(Philotic.logger).to receive(:error)

          subject.connect!

        end
      end
    end

    context 'not connected' do
      context 'success' do
        specify do
          expect(subject).to receive(:connected?).and_return(true)
          expect(subject).not_to receive(:start_connection!)
          expect(subject).not_to receive(:set_exchange_return_handler!)

          subject.connect!

        end
      end
    end
  end

  describe '.start_connection!' do
    let(:connection) { double }
    specify do
      expect(Bunny).to receive(:new).with(Philotic::Config.rabbit_url, Philotic::Connection.connection_settings).and_return(connection)
      expect(connection).to receive(:start)

      Philotic::Connection.start_connection!
    end
  end
end