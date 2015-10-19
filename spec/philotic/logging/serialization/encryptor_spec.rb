require 'spec_helper'


module Philotic
  module Serialization
    describe Encryptor do
      let(:encryption_key) { 'super_secret_key' }

      describe '.content_type' do
        specify { expect(subject.content_type).to eq 'application/json' }
      end

      describe '.serialization' do
        specify { expect(subject.serialization).to eq :encrypted }
      end

      describe '.default_encryption_key' do
        it 'pulls the key from Philotic.config' do
          expect(Philotic.config).to receive(:encryption_key) { encryption_key }
          expect(subject.default_encryption_key).to eq encryption_key
        end

        describe 'encryption' do
          let(:metadata) { {headers: {}} }
          let(:payload) {'payload'}

          it 'encrypts and decrypts the payload' do
            expect(Philotic.config).to receive(:encryption_key) { encryption_key }

            expect(subject.load(subject.dump(payload, metadata), metadata)).to eq payload
          end
        end
      end
    end
  end
end