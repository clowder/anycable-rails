# frozen_string_literal: true

require "anycable/rails/connections/session_proxy"

module AnyCable
  module Rails
    module Connections
      module PersistentSession
        def handle_open
          super.tap { commit_session! }
        end

        def handle_channel_command(*)
          super.tap { commit_session! }
        end

        def request
          @request ||= super.tap do |req|
            next unless socket.session
            req.env[::Rack::RACK_SESSION] =
              SessionProxy.new(req.env[::Rack::RACK_SESSION], socket.session)
          end
        end

        private

        def commit_session!
          return unless defined?(@request) && request.session.respond_to?(:loaded?) && request.session.loaded?

          socket.session = request.session.to_json
        end
      end
    end
  end
end

AnyCable::Rails::Connection.prepend(
  AnyCable::Rails::Connections::PersistentSession
)
