require 'spec_helper'

describe Philotic::Connection do
  let(:connection){ Philotic::Connection }
  subject { connection } 
  
  describe "config" do
    it "should return the Philotic::Config singleton" do
      subject.config.should == Philotic::Config
    end
  end
  
  describe "exchange" do
    #TODO make sure rabbit is running for CI to run this
    xit "should return an instance of AMQP::Exchange" do
      subject.exchange.should be_a AMQP::Exchange
    end
  end
end
