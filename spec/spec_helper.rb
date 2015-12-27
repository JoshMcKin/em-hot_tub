require 'rubygems'
require 'rspec'
require 'rspec/autotest'
require 'em-hot_tub'
require 'em-http-request'
require "em-synchrony"
require "em-synchrony/em-http"
require 'helpers/moc_pool'
require 'helpers/moc_client'
require 'helpers/server'
require 'logger'


# EM::HotTub.logger = Logger.new(STDOUT)
# EM::HotTub.trace = true

RSpec.configure do |config|

  config.expect_with :rspec do |expectations|

    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  config.before(:suite) do
    HotTub::Server.run
    HotTub::Server2.run
  end

  config.after(:suite) do
    HotTub::Server.teardown
    HotTub::Server2.teardown
  end

end
