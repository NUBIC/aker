require 'aker'
require 'rack'

module Aker::Form
  ##
  # Utility methods for building an HTTP response suitable for the form mode.
  module HtmlResponse
    def html_response(*args)
      ::Rack::Response.new(*args) do |resp|
        resp['Content-Type'] = 'text/html'
        yield resp if block_given?
      end
    end
  end
end
