require 'spec_helper'
require 'philotic/config'
require 'philotic/connection'

describe Philotic::Config do

  describe '#load_file' do
    let(:config_file_path) { './philotic.yml.example' }
    let(:config) { YAML.load_file(config_file_path)['test'] }

    subject { described_class.new(instance_double Philotic::Connection) }

    it 'properly loads config' do
      subject.load_file config_file_path, 'test'
      expect(config.keys).to_not be :empty?
      config.keys.each do |key|
        expect(subject.send(key)).to eq config[key]
      end
    end
  end


  describe '#message_return_handler' do
    let(:logger) { instance_double(Logger) }
    let(:basic_return) { instance_double(Bunny::ReturnInfo) }
    let(:metadata) { instance_double(Bunny::Session) }
    let(:payload) { {foo: 'bar'}.to_json }
    let(:connection) { instance_double(Philotic::Connection, logger: logger) }

    subject { described_class.new(connection) }

    it 'logs a warning do' do

      expect(logger).to receive(:warn)
      subject.message_return_handler.call basic_return, metadata, payload
    end

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
