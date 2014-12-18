require 'spec_helper'
require 'philotic/config'
require 'philotic/connection'

describe Philotic::Config do

  describe '#defaults' do
  end

  describe '#load' do
  end

  describe '#load_file' do
  end

  describe '#parse_rabbit_uri' do
    let(:url) { 'amqp://user:pass@host:12345/vhost' }
    let(:config) { Philotic::Connection.new.config }
    before do
      config.rabbit_url = url
    end
    subject { lambda { config.parse_rabbit_uri } }

    it do
      should change {
               [
                   config.rabbit_user,
                   config.rabbit_password,
                   config.rabbit_host,
                   config.rabbit_port,
                   config.rabbit_vhost,
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
