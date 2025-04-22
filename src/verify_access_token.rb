require "jwt"

module Foobara
  module Auth
    class VerifyAccessToken < Foobara::Command
      inputs do
        # TODO: we should add a processor that flags an attribute as sensitive so we can scrub
        access_token :string, :required, :sensitive
      end

      result do
        verified :boolean, :required
        failure_reason :string, :allow_nil, one_of: %w[invalid expired cannot_verify]
        payload :associative_array, :allow_nil
        headers :associative_array, :allow_nil
      end

      def execute
        decode_access_token
        set_verified_flag

        verified_flag_payload_and_headers
      end

      attr_accessor :verified, :payload, :headers, :failure_reason

      def decode_access_token
        self.payload, self.headers = JWT.decode(access_token, jwt_secret)
      rescue JWT::VerificationError
        self.failure_reason = "cannot_verify"
      rescue JWT::ExpiredSignature
        self.failure_reason = "expired"
      rescue JWT::DecodeError
        self.failure_reason = "invalid"
      end

      def set_verified_flag
        self.verified = !failure_reason
      end

      def verified_flag_payload_and_headers
        {
          verified:,
          failure_reason:,
          payload:,
          headers:
        }
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
