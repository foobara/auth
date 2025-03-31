require "jwt"

module Foobara
  module Auth
    class BuildAccessToken < Foobara::Command
      inputs do
        user Types::User, :allow_nil
        token_ttl :integer, default: 30 * 60
      end

      result :string, :sensitive_exposed

      def execute
        determine_timestamps
        generate_access_token

        access_token
      end

      attr_accessor :access_token, :expires_at

      def determine_timestamps
        now = Time.now
        self.expires_at = now + token_ttl
      end

      def generate_access_token
        payload = { sub: user.id, exp: expires_at.to_i }

        self.access_token = JWT.encode(payload, jwt_secret, "HS256")
      end

      def jwt_secret
        jwt_secret_text = ENV.fetch("JWT_SECRET", nil)

        unless jwt_secret_text
          # :nocov:
          raise "You must set the JWT_SECRET environment variable"
          # :nocov:
        end

        jwt_secret_text
      end
    end
  end
end
