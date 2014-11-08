require 'spec_helper'

# create 'deep' inheritance to test self.inherited
class TestEventParent < Philotic::Event
end
class TestEvent < TestEventParent
end

describe Philotic::Event do
  let(:event) { TestEvent.new }
  subject { event }

  Philotic::Routable::ClassMethods.instance_methods.sort.each do |method_name|
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

  describe 'message_metadata' do
    it 'should have a timestamp' do
      Timecop.freeze
      expect(subject.message_metadata).to eq(timestamp: Time.now.to_i)
    end

    it 'should reflect changes in the event properties' do
      expect(subject.message_metadata[:app_id]).to eq nil
      subject.app_id = 'ANSIBLE'
      expect(subject.message_metadata[:app_id]).to eq 'ANSIBLE'
    end
  end
  describe 'headers' do
    it 'should include :philotic_product' do
      expect(subject.headers.keys).to include :philotic_product
    end
  end
end
