source 'https://rubygems.org'

ruby '2.0.0'

gem 'rails', '~> 4.0.0'
gem 'jquery-rails', '~> 3.0.4'

# tmp backward compat helpers
gem 'protected_attributes'

# ???
gem 'sinatra', '~>1.4.3'
gem 'json', '~> 1.7.7'
gem 'nokogiri', '~> 1.6.0'
gem 'sprockets'

gem 'unicorn'

gem 'uuid', '~> 2.3.7' # used to generate unique filenames for download reports - overkill much?

# 911
gem 'pagerduty'
gem 'bugsnag'

# ActiveRecord extensions
gem 'activerecord-import'
gem 'ar-octopus'
gem 'bitmask_attributes'
gem 'will_paginate', '~> 3.0.4'
gem 'deep_cloneable', '~> 1.5.3'

# Assets
gem 'slim', '~>2.0.0'

# Auth/z
gem 'cancan', '~>1.6.10'

# Background
gem 'resque', '~> 1.24.1'
gem 'resque-scheduler', '~> 2.0.1', :require => 'resque_scheduler'
gem 'resque-lock', '~> 1.1.0'
gem 'resque-loner', '~>1.2.1'
gem 'sidekiq', '~> 2.13.0'
gem 'sidekiq-failures', '~> 0.2.1'

# Databases
gem 'mysql2' #, '~> 0.3.13'
gem 'redis', '~> 3.0.4'
gem 'redis-objects', '~>0.7.0',:require => 'redis/objects'
gem 'hiredis', '~>0.4.5'
gem 'em-hiredis', '~>0.2.1'

# DNS
gem 'em-resolv-replace' # non-blocking lookups for eventmachine

# EventMachine
gem 'eventmachine', '1.0.3'
gem 'em-http-request', '~> 1.1.0'
gem 'em-synchrony', '~> 1.0.3'

# Files
gem 'paperclip', '~> 3.5.0'
gem 'rubyzip'

# Forms
gem 'formtastic', '~>2.2.1'
gem 'dynamic_form', '~> 1.1.4'
gem 'cocoon'

# HTTP client
gem 'faraday'
gem 'faraday_middleware'
gem 'faraday-cookie_jar'

# Logging
gem 'lograge', '~>0.2.0'

# Reporting
gem 'ruport'
gem 'acts_as_reportable'

# Text -> HTML processors
gem 'redcarpet'

# Provider clients
gem 'aws-sdk'
gem 'platform-api'
gem 'pusher', '~> 0.11.3'
gem 'stripe', '~>1.8.4'
gem 'twilio', '~> 3.1.1'
gem 'twilio-ruby', '~> 3.10.0'

# SMTP
gem 'mandrill-api', '~>1.0.37'

# Monitoring
gem 'librato-rails'
gem 'newrelic_rpm'
gem 'newrelic-redis'
group :production, :heroku, :heroku_staging do
  gem 'rack-timing'
  gem 'rack-queue-metrics', git: "https://github.com/heroku/rack-queue-metrics.git", branch: "cb-logging"
end

# redis lua scripts
gem 'wolverine'

group :development do
  gem 'annotate'
  gem 'guard'
  gem 'guard-rspec'
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'rb-fsevent'
  gem 'showoff-io'
  gem 'foreman'
  gem 'capistrano'
  gem 'capistrano_colors'
  gem 'capistrano-multiconfig'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'bullet'
end

group :development, :test, :e2e do
  gem 'rspec-rails'
  gem 'rspec-its' # its is not in rspec 3
  gem 'rspec-activemodel-mocks' # mock_model is not in rspec 3
  gem 'rspec-collection_matchers' # expect(collection).to have(1).thing is not in rspec 3
  gem 'forgery', '0.6.0'
  gem 'hirb'
  gem 'rspec-instafail'
  gem 'pry'
  gem 'pry-debugger'
  gem 'compass'
  # cli tool to reload app when files change, whether background, web, initializer, etc
  # usage e.g. rerun foreman start
  gem 'rerun'
end

group :test, :e2e do
  gem 'factory_girl_rails'
  gem 'shoulda'
  gem 'simplecov', require: false
  gem 'database_cleaner'
  gem 'capybara'
  gem 'launchy'
  gem 'timecop'
  gem 'webmock'
  gem 'vcr'
  gem 'capybara-webkit'
end
