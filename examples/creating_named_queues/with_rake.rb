#!/usr/bin/env ruby
$:.unshift File.expand_path('../../../lib', __FILE__)
$stdout.sync = true

require 'philotic'
require 'rake'

require 'philotic/tasks'
# equivelant of:
# rake philotic:init_queues[examples/creating_named_queues/philotic_queues.yml]
Rake::Task['philotic:init_queues'].invoke(File.join(File.dirname(__FILE__), 'philotic_queues.yml'))
