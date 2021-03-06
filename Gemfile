source 'https://rubygems.org'

gem 'rails', '~> 3.2.3'

gem 'pg'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'compass-rails'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
  gem 'chosen-rails'
  gem 'jquery-ui-rails'
end

gem 'jquery-rails'
gem 'haml-rails'
gem 'coffee-filter'
gem 'sugar-rails'

gem 'geocoder'
gem 'simple_form', '~> 2.0'

gem 'decent_exposure'
gem 'kaminari'
gem 'ancestry'
gem 'curb'
gem 'tire', '0.4.2'
gem 'rocket_tag'
gem 'airbrake'

# versioning
gem 'paper_trail', '~> 2'

# admin panel
gem 'activeadmin'
gem 'meta_search',    '>= 1.1.0.pre'
gem 'devise'
gem 'cancan'

gem 'multi_json', '~> 1.0.3'
gem 'json', '~> 1.5.4'
gem 'remote_table'

# import data from sqlite
gem 'data_mapper', '~> 1.2'
gem 'dm-chunked_query'
gem 'dm-sqlite-adapter'
gem 'unicode'
gem 'gon'
gem 'high_voltage'
gem 'newrelic_rpm'
gem 'rails_config', '0.2.5'
gem 'dalli'
gem 'will_cache'

# background jobs
gem 'whenever', :require => false

# bot secrity
gem 'recaptcha', :require => 'recaptcha/rails'

group :development, :test do
  # for debugging
  gem 'ruby-debug19'
  gem 'pry-rails'

  # for routes in /rails/routes
  gem 'sextant'
  gem 'guard-cucumber'
end

# assets javascript compiler
gem 'therubyracer', :group => :production

group :test do
  # for defining tests
  gem 'cucumber-rails', :require => false
  gem 'rspec-rails',  '~> 2.0'
  gem 'factory_girl_rails'
  gem 'database_cleaner'
  gem 'capybara'

  # for running tests
  gem 'spork-rails'
  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-spork'
  gem 'growl'
  gem 'rb-fsevent'

  gem 'shoulda-matchers'
  gem 'simplecov', :require => false
end
