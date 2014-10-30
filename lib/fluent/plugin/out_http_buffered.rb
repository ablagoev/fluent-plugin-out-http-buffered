# encoding: utf-8

module Fluent
  # Main Output plugin class
  class HttpBufferedOutput <  Fluent::BufferedOutput
    Fluent::Plugin.register_output('http_buffered', self)

    def initialize
      super
      require 'net/http'
      require 'uri'
    end

    # Endpoint URL ex. localhost.local/api/
    config_param :endpoint_url, :string

    # statuses under which to retry
    config_param :http_ok_statuses, :string, default: ''

    # read timeout for the http call
    config_param :http_read_timeout, :float, default: 2.0

    # open timeout for the http call
    config_param :http_open_timeout, :float, default: 2.0

    # nil | 'none' | 'basic'
  config_param :authentication, :string, :default => nil
  config_param :username, :string, :default => ''
  config_param :password, :string, :default => ''

    def configure(conf)
      super

      #@timef = TimeFormatter.new(@time_format, @localtime)
      # Check if endpoint URL is valid
      unless @endpoint_url =~ /^#{URI.regexp}$/
        fail Fluent::ConfigError, 'endpoint_url invalid'
      end

      begin
        @uri = URI.parse(@endpoint_url)
      rescue URI::InvalidURIError
        raise Fluent::ConfigError, 'endpoint_url invalid'
      end

      # Parse http statuses
      @statuses = @http_ok_statuses.split(',').map { |status| status.to_i }

      @statuses = [] if @statuses.nil?


      @auth = case @authentication
            when 'basic' then :basic
            else
              :none
            end

#      @http = Net::HTTP.new(@uri.host, @uri.port)
#      @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
#      @http.read_timeout = @http_read_timeout
#      @http.open_timeout = @http_open_timeout
#      @http.use_ssl = @uri.scheme == 'https'

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
      #time_str = @timef.format(time)
      record["msg"] + "\n"
    end

   def set_header(req)
    req
  end


    def write(chunk)
      http = Net::HTTP.new(@uri.host, @uri.port)
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.read_timeout = @http_read_timeout
      http.open_timeout = @http_open_timeout
      http.use_ssl = @uri.scheme == 'https'

      $log.info "Sending data to #{@uri.request_uri}"
      #data = []
        data = chunk
      request = create_request(data)

      begin
        response = http.start do |ht|
      #    request = create_request(data)
          ht.request request
        end
        $log.warn "response status is  #{response.code}"

        unless @statuses.include? response.code.to_i

          # Raise an exception so that fluent retries
          fail "Server returned bad status: #{response.code}"
        end
      rescue StandardError, OpenSSL::SSL::SSLError, IOError, EOFError, SystemCallError => e
        # server didn't respond
        $log.warn "Net::HTTP.#{request.method.capitalize} raises exception: #{e.class}, '#{e.message}'"
        fail e.message
 ensure
        begin
          http.finish
        rescue
        end
      end
    end

    protected

      def create_request(data)

        request = Net::HTTP::Post.new(@uri.request_uri)

         #$log.warn "data is  #{data}"
        # Body
        request.body =data.read
         # Headers
        request['Content-Type'] = 'application/json'

       set_header(request)
        #$log.warn "request is  #{request}"

        if @auth and @auth == :basic
                request.basic_auth(@username, @password)
        end
        #@http.use_ssl = true
        request
      end
  end
end
