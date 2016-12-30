require 'rspec'

if ENV.fetch('CODECLIMATE_REPO_TOKEN', false)
  require 'simplecov'
  SimpleCov.start
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'fail_to_ban'
