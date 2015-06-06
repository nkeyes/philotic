#!/usr/bin/env ruby
$:.unshift File.expand_path('../../../lib', __FILE__)
$stdout.sync = true

require 'philotic'

# explicitly create named queues for this example
# Philotic.config.initialize_named_queues must be truthy to run Philotic.initialize_named_queue!
Philotic.config.initialize_named_queues = true

Philotic.initialize_named_queue!('mauve_queue', bindings: [{:'x-match' => 'all', hue: :M, available: true}])
Philotic.initialize_named_queue!('fuchsia_queue', bindings: [{:'x-match' => 'all', hue: :F, available: true}])
Philotic.initialize_named_queue!('test_queue', bindings: [{ :'x-match' => 'any', hue: :M, available: true }])
Philotic.initialize_named_queue!('flaky_queue', bindings: [{ :'x-match' => 'any', hue: :M, available: true }])
