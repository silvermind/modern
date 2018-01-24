# frozen_string_literal: true

require "rack"

require "deep_dup"
require "ice_nine"

require "modern/configuration"
require "modern/description/descriptor"

require "modern/response"

require "modern/app/error_handling"

require "modern/errors"

module Modern
  # `App` is the core of Modern. Some Rack application frameworks have you
  # inherit from them to generate your application; however, that makes it
  # pretty difficult to control immutability of the underlying routes. Since we
  # have a need to generate an OpenAPI specification off of our routes and
  # our behaviors, this is not an acceptable trade-off. As such, Modern expects
  # to be passed a {Modern::Description::Descriptor}, which specifies a set of
  # {Modern::Description::Route}s. The app then dispatches requests based on
  # these routes.
  class App
    include Modern::App::ErrorHandling

    def initialize(descriptor, configuration)
      @descriptor = IceNine.deep_freeze(DeepDup.deep_dup(descriptor))
      @configuration = IceNine.deep_freeze(DeepDup.deep_dup(configuration))
    end

    def call(env)
      request = Rack::Request.new(env)
      response = Modern::Response.new
      route = find_route(request)

      begin
        raise Modern::Errors::NotFoundError if route.nil?

        response.finish
      rescue Modern::Redirect => redirect
        response.redirect(redirect.target, redirect.status)
      rescue StandardError => err
        handle_error(response, err)
        response.finish
      end
    end

    private

    def find_route(_request)
      # TODO: This is an O(n) matcher. We have options for improving this.
      #       - Caching most recent N URL resolutions.
      #       - Path trie. (Write the traversal iteratively.)
      nil
    end
  end
end