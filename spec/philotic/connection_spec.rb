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
          expect(Philotic.logger).to receive(:info)

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
          expect(Philotic.logger).to receive(:info)

          subject.connect!

        end
      end
    end
  end

  describe '.start_connection!' do

  end
end