#!/usr/bin/env ruby
$:.unshift File.expand_path('../../../lib', __FILE__)
$stdout.sync = true

require 'philotic'
require 'awesome_print'

Philotic.config.load_file(File.join(File.dirname(__FILE__), '../../', 'Philotic.yml.example'))

Philotic.subscribe('fuchsia_queue') do |message|
  ap message.attributes
end

Philotic.subscribe('mauve_queue') do |message|
  ap message.attributes
end

Philotic.subscriber.endure