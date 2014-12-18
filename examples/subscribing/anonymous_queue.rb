#!/usr/bin/env ruby
$:.unshift File.expand_path('../../../lib', __FILE__)
$stdout.sync = true

require 'philotic'
require 'awesome_print'

philotic = Philotic::Connection.new

philotic.config.load_file(File.join(File.dirname(__FILE__), '../../', 'philotic.yml.example'))


philotic.subscriber.subscribe(philotic_firehose: true) do |metadata, message|
  ap message[:attributes]
end

philotic.subscriber.endure