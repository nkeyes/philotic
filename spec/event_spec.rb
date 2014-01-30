require 'spec_helper'

# create 'deep' inheritance to test self.inherited
class TestEventParent < Philotic::Event
end
class TestEvent < TestEventParent
end

describe Philotic::Event do
  let(:event){ TestEvent.new }
  subject { event }
  
  Philotic::Routable::ClassMethods.instance_methods.sort.each do |method_name|
    specify { subject.class.methods.should include method_name.to_sym }
  end
  
  Philotic::MESSAGE_OPTIONS.each do |method_name|
    specify { subject.methods.should include method_name.to_sym }
    specify { subject.methods.should include "#{method_name}=".to_sym }
  end
  
  Philotic::EVENTBUS_HEADERS.each do |method_name|
    specify { subject.methods.should include method_name.to_sym }
    specify { subject.methods.should include "#{method_name}=".to_sym }
  end
  
  describe "message_metadata" do
    it "should have a timestamp" do
      Timecop.freeze
      subject.message_metadata.should == {timestamp: Time.now.to_i}
    end
    
    it "should reflect changes in the event properties" do
      subject.message_metadata[:app_id]. should == nil
      subject.app_id = 'ANSIBLE'
      subject.message_metadata[:app_id]. should == 'ANSIBLE'
    end
  end
  describe "headers" do
    it "should include :philotic_product" do
      subject.headers.keys.should include :philotic_product
    end
  end
end
