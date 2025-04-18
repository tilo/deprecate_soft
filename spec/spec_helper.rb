# frozen_string_literal: true

require 'simplecov'

SimpleCov.track_files 'lib/**/*.rb'
SimpleCov.start do
  add_filter '/spec/'
  add_filter 'lib/deprecate_soft/version.rb'
end

require 'bundler/setup'
require 'deprecate_soft'
require 'pry'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  config.order = :random

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
