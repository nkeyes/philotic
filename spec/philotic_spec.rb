require 'spec_helper'
require 'philotic'

describe Philotic do
  describe '.connection' do
    specify do
      expect(Philotic.connection.class).to eq(Philotic::Connection)
    end
  end
end
