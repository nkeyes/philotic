#!/usr/bin/env ruby
$:.unshift File.expand_path('../../../lib', __FILE__)
$stdout.sync = true

require 'philotic'

# explicitly create named queues for this example
# ENV['PHILOTIC_INITIALIZE_NAMED_QUEUE'] must equal 'true' to run Philotic.initialize_named_queue!
ENV['PHILOTIC_INITIALIZE_NAMED_QUEUE'] = 'true'
Philotic.initialize_named_queue!('male_queue', bindings: [{:'x-match' => 'all', gender: :M, available: true}])
Philotic.initialize_named_queue!('female_queue', bindings: [{:'x-match' => 'all', gender: :F, available: true}])
Philotic.initialize_named_queue!('test_queue', bindings: [{ :'x-match' => 'any', gender: :M, available: true }])
Philotic.initialize_named_queue!('flaky_queue', bindings: [{ :'x-match' => 'any', gender: :M, available: true }])
