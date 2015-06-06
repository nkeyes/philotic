#!/usr/bin/env ruby
$:.unshift File.expand_path('../../../lib', __FILE__)
$stdout.sync = true

require 'philotic'
require 'rake'

require 'philotic/tasks'
# equivelant of:
# PHILOTIC_DELETE_EXISTING_QUEUES=true rake philotic:init_queues[examples/creating_named_queues/philotic_queues.yml]

# Philotic.config.self.config.delete_existing_queues must be truthy to redefine existing queues
ENV['PHILOTIC_DELETE_EXISTING_QUEUES'] = 'true'
Rake::Task['philotic:init_queues'].invoke(File.join(File.dirname(__FILE__), 'philotic_queues.yml'))
