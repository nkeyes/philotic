#!/usr/bin/env ruby
$:.unshift File.expand_path('../../../lib', __FILE__)
$stdout.sync = true

require 'philotic'
require 'awesome_print'

Philotic::Config.load_file(File.join(File.dirname(__FILE__), '../../', 'philotic.yml.example'))

Philotic::Subscriber.subscribe('female_queue') do |metadata, message|
  ap message[:attributes]
end

Philotic::Subscriber.subscribe('male_queue') do |metadata, message|
  ap message[:attributes]
end

Philotic::Subscriber.endure