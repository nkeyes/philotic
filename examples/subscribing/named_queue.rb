#!/usr/bin/env ruby
$:.unshift File.expand_path('../../../lib', __FILE__)
$stdout.sync = true

require 'philotic'
require 'awesome_print'

Philotic.subscribe('test_queue') do |message|
  ap message.attributes
end

Philotic.subscriber.endure