# encoding: utf-8
require 'coveralls'
Coveralls.wear!

require 'rubygems'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts 'Run `bundle install` to install missing gems'
  exit e.status_code
end

require 'test/unit'
require 'rspec/mocks'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'fluent/test'
require 'fluent/plugin/out_http_buffered'

# TestCase base class
class Test::Unit::TestCase
  def setup_rspec(test_case)
    RSpec::Mocks.setup(test_case)
  end

  def verify_rspec
    RSpec::Mocks.verify
  end

  def teardown_rspec
    RSpec::Mocks.teardown
  end
end
