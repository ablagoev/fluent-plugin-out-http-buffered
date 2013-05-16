module Fluent

  class HttpBufferedOutput < Fluent::BufferedOutput
    Fluent::Plugin.register_output('http_buffered', self)

    def initialize
      super
      require 'net/http'
      require 'uri'
    end

    # Endpoint URL ex. localhost.local/api/
    config_param :endpoint_url, :string

    # statuses under which to retry
    config_param :http_retry_statuses, :string, :default => ""

    # read timeout for the http call
    config_param :http_read_timeout, :float, :default => 2.0

    # open timeout for the http call
    config_param :http_open_timeout, :float, :default => 2.0

    def configure(conf)
      super

      #Check if endpoint URL is valid
      unless @endpoint_url =~ /^#{URI::regexp}$/
        raise Fluent::ConfigError, "endpoint_url invalid"
      end
      
      begin
        @uri = URI::parse(@endpoint_url)
      rescue URI::InvalidURIError
        raise Fluent::ConfigError, "endpoint_url invalid"
      end

      #Parse http statuses
      @statuses = @http_retry_statuses.split(",").map { |status| status.to_i}

      if @statuses.nil?
        @statuses = []
      end

      @http = Net::HTTP.new(@uri.host, @uri.port)
      @http.read_timeout = @http_read_timeout
      @http.open_timeout = @http_open_timeout
    end

    def start
      super
    end

    def shutdown
      super
      begin
        @http.finish
      rescue
      end
    end

    def format(tag, time, record)
      [tag, time, record].to_msgpack
    end

    def write(chunk)
      data = []
      chunk.msgpack_each do |(tag,time,record)|
        data << [tag, time, record]
      end

      request = create_request(data)

      begin
        response = @http.start do |http|
          request = create_request(data)
          http.request request
        end

        if @statuses.include? response.code.to_i
          #Raise an exception so that fluent retries
          raise "Server returned bad status: #{response.code}"
        end
      rescue IOError, EOFError, SystemCallError
        # server didn't respond 
        $log.warn "Net::HTTP.#{request.method.capitalize} raises exception: #{$!.class}, '#{$!.message}'"
      ensure
        begin
          @http.finish
        rescue
        end
      end
    end

    protected
      def create_request(data)
        request= Net::HTTP::Post.new(@uri.request_uri)

        #Headers
        request['Content-Type'] = 'application/json'

        #Body
        request.body = JSON.dump(data)

        request
      end
  end
end