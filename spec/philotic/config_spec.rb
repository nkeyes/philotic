require 'spec_helper'

describe Philotic::Config do

  describe '.defaults' do
  end

  describe '.load' do
  end

  describe '.load_file' do
  end

  describe '.parse_rabbit_uri' do
    let(:url) { 'amqp://user:pass@host:12345/vhost' }
    before do
      Philotic::Config.rabbit_url = url
    end
    subject { lambda { Philotic::Config.parse_rabbit_uri } }

    it do
      should change {
        [
            Philotic::Config.rabbit_user,
            Philotic::Config.rabbit_password,
            Philotic::Config.rabbit_host,
            Philotic::Config.rabbit_port,
            Philotic::Config.rabbit_vhost,
        ]
      }
             .to [
                     'user',
                     'pass',
                     'host',
                     12345,
                     'vhost',
                 ]
    end
  end
end
