# -*- encoding: utf-8 -*-
require File.expand_path('../lib/philotic/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors     = ['Nathan Keyes']
  gem.email       = ['nkeyes@gmail.com']
  gem.description = %q{Lightweight, opinionated wrapper for using RabbitMQ headers exchanges}
  gem.summary     = %q{Lightweight, opinionated wrapper for using RabbitMQ headers exchanges}
  gem.homepage    = 'https://github.com/nkeyes/philotic'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'philotic'
  gem.require_paths = ['lib']
  gem.version       = Philotic::VERSION
  gem.licenses      = ['MIT']


  gem.add_development_dependency 'codeclimate-test-reporter'
  gem.add_development_dependency 'bundler', '~> 1.6'
  gem.add_development_dependency 'evented-spec', '~> 0.9'
  gem.add_development_dependency 'pry', '~> 0.10'
  gem.add_development_dependency 'rake', '~> 10.3'
  gem.add_development_dependency 'rspec', '~> 3.1'
  gem.add_development_dependency 'rspec-its', '~> 1.1'
  gem.add_development_dependency 'timecop', '~> 0.7'
  gem.add_development_dependency 'simplecov'

  gem.add_dependency 'activesupport', '>= 3.2'
  gem.add_dependency 'activerecord', '>= 3.2'
  gem.add_dependency 'awesome_print', '~> 1.2'
  gem.add_dependency 'bunny', '~> 1.2.1'
  gem.add_dependency 'json', '~> 1.8'
end
