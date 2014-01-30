# -*- encoding: utf-8 -*-
require File.expand_path('../lib/philotic/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['Nathan Keyes']
  gem.email         = ['nkeyes@gmail.com']
  gem.description   = %q{Lightweight, opinionated wrapper for using RabbitMQ headers exchanges}
  gem.summary       = %q{Lightweight, opinionated wrapper for using RabbitMQ headers exchanges}
  gem.homepage      = 'https://github.com/nkeyes/philotic'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'philotic'
  gem.require_paths = ['lib']
  gem.version       = Philotic::VERSION
  gem.licenses       = ['MIT']

  gem.add_dependency 'activerecord', '~> 3.2.8'
  gem.add_dependency 'amqp'
  gem.add_dependency 'awesome_print'
  gem.add_dependency 'json'
  gem.add_dependency 'log4r'
  gem.add_dependency 'pry-nav'
end
