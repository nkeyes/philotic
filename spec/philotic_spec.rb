require 'spec_helper'
require 'philotic'

describe Philotic do
  describe '.connection' do
    specify do
      expect(Philotic.connection.class).to eq(Philotic::Connection)
    end
  end

  describe 'delegation' do
    it 'should delegate to the connection instance' do
      (Philotic.connection.public_methods(false) - [:connection]).each do |method|
        expect(Philotic.connection).to receive(method)
        Philotic.send "#{method}"
      end
    end
  end
end
