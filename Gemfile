source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.1'

gem 'rails', '~> 6.0.3'
gem 'puma', '~> 5.0'
gem 'webpacker', '~> 4.0'
gem 'rails_admin'

gem 'devise'
gem 'devise-i18n'
gem 'rails-i18n', '~> 6.0.0'

group :development, :test do
  gem 'sqlite3'
  gem 'byebug'
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'shoulda-matchers'
  gem 'rails-controller-testing'
  gem 'capybara'
  gem 'launchy' # save_and_open_page in features spec
  gem 'database_cleaner-active_record'
end

group :development do
  gem 'web-console'
end

group :test do
  gem 'test-prof'
end

group :production do
  gem 'rails_12factor'
  gem 'pg'
end
