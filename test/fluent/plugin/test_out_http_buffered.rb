require 'helper'
require 'yaml'

class HttpBufferedOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    endpoint_url  http://local.endpoint
  ]

  #Used to test invalid method config
  CONFIG_METHOD = %[
    endpoint_url local.endpoint
    http_method  invalid_method
  ]

  def create_driver(conf = CONFIG)
    Fluent::Test::BufferedOutputTestDriver.new(Fluent::HttpBufferedOutput).configure(conf)
  end

  def test_configure
    d = create_driver
    assert_equal 'http://local.endpoint', d.instance.instance_eval{ @endpoint_url }
    assert_equal "", d.instance.instance_eval{ @http_retry_statuses }
    assert_equal [], d.instance.instance_eval{ @statuses }
    assert_equal 2.0, d.instance.instance_eval{ @http_read_timeout }
    assert_equal 2.0, d.instance.instance_eval{ @http_open_timeout }
  end

  def test_invalid_endpoint
    assert_raise Fluent::ConfigError do
      d = create_driver("endpoint_url \\@3")
    end

    assert_raise Fluent::ConfigError do
      d = create_driver("endpoint_url google.com")
    end
  end

  def test_write_status_retry
    setup_rspec(self)

    d = create_driver(%[
        endpoint_url http://local.endpoint
        http_retry_statuses 500
      ])

    d.emit("abc")

    http = double()
    http.stub(:start).and_yield(http)
    http.stub(:request) do
      response = OpenStruct.new
      response.code = "500"
      response
    end

    d.instance.instance_eval{ @http = http }

    assert_raise Fluent::HttpBufferedRetryException do
      d.run
    end

    verify_rspec
    teardown_rspec
  end

  def test_write
    setup_rspec(self)

    d = create_driver("endpoint_url http://www.google.com/")

    d.emit("message")
    http = double("Net::HTTP")
    http.stub(:start).and_yield(http)
    http.stub(:request) do |request|
      assert(request.body =~ /message/)
      response = OpenStruct.new
      response.code = "200"
      response
    end

    d.instance.instance_eval{ @http = http }

    data = d.run

    verify_rspec
    teardown_rspec
  end
end