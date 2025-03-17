require "jwt"
require "securerandom"

require_relative "create_token"
require_relative "verify_password"
require_relative "verify_token"

module Foobara
  module Auth
    class Login < Foobara::Command
      class InvalidPasswordError < Foobara::RuntimeError
        context({})
        message "Invalid password"
      end

      depends_on CreateToken, VerifyPassword

      inputs do
        user Types::User, :required
        plaintext_password :string, :required
        # Configure these instead of defaulting them here?
        token_ttl :integer, default: 30 * 60
        refresh_token_ttl :integer, default: 7 * 24 * 60 * 60
      end

      result do
        access_token :string, :required
        refresh_token :string, :required
      end

      def execute
        verify_password
        # TODO: DRY these 5 up
        determine_timestamps
        generate_access_token
        determine_token_group
        generate_new_refresh_token
        save_new_refresh_token_on_user

        tokens
      end

      attr_accessor :access_token, :new_refresh_token, :now, :expires_at, :token_group

      def verify_password
        unless run_subcommand!(VerifyPassword, user:, plaintext_password:)
          add_runtime_error(InvalidPasswordError)
        end
      end

      def determine_timestamps
        self.now = Time.now
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

      def determine_token_group
        self.token_group = SecureRandom.uuid
      end

      def generate_new_refresh_token
        self.new_refresh_token = run_subcommand!(CreateToken, expires_at:, token_group:)
      end

      def save_new_refresh_token_on_user
        # TODO: maybe override #<< on these objects to dirty the entity??
        user.refresh_tokens += [*user.refresh_tokens, new_refresh_token[:token_record]]
      end

      def tokens
        {
          access_token:,
          refresh_token: new_refresh_token[:token_string]
        }
      end
    end
  end
end
