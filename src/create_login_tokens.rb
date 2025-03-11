require "jwt"
require "securerandom"

require_relative "create_token"

module Foobara
  module Auth
    class CreateLoginTokens < Foobara::Command
      class MustProvideEitherRefreshTokenOrPasswordError < Foobara::RuntimeError
        message "You must provide either a refresh token or a password"
      end

      class InvalidRefreshTokenError < Foobara::RuntimeError
        message "Invalid refresh token"
      end

      class InvalidPasswordError < Foobara::RuntimeError
        message "Invalid password"
      end

      depends_on CreateToken

      inputs do
        user Types::User, :required
        plaintext_password :string, :allow_nil
        refresh_token_text :string, :allow_nil
        token_ttl :integer, default: 30 * 60
        refresh_token_ttl :integer, default: 7 * 24 * 60 * 60
      end

      result do
        access_token :string, :required
        refresh_token :string, :required
      end

      def execute
        if refresh_token_text
          load_refresh_token
          verify_refresh_token
          # Delete it instead maybe?
          mark_refresh_token_as_used
        else
          verify_password
        end

        determine_timestamps
        generate_access_token
        generate_new_refresh_token

        tokens
      end

      attr_accessor :access_token, :new_refresh_token, :now, :expires_at, :refresh_token

      def validate
        super

        if (refresh_token_text.nil? || refresh_token_text.empty?) &&
           (plaintext_password.nil? || plaintext_password.empty?)
          add_runtime_error(MustProvideEitherRefreshTokenOrPasswordError)
        end
      end

      def load_refresh_token
        self.refresh_token = user.refresh_tokens
      end

      def verify_refresh_token
        valid = user.refresh_tokens.any? do |refresh_token|
          run_subcommand!(VerifyApiKey, token: refresh_token.token)
        end

        unless valid
          add_runtime_error(InvalidRefreshTokenError)
        end
      end

      def mark_refresh_token_as_used
        refresh_token.used = true
      end

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
        payload = {
          user_id: user.id,
          username: user.username,
          exp: expires_at.to_i
        }

        self.access_token = JWT.encode(payload, secret, "HS256")
      end

      def jwt_secret
        jwt_secret_text = ENV.fetch("JWT_SECRET", nil)

        unless jwt_secret_text
          raise "You must set the JWT_SECRET environment variable"
        end

        jwt_secret_text
      end

      def generate_new_refresh_token
        run_subcommand!(CreateToken, token_ttl: refresh_token_ttl)
        token_group = existing_refresh_token&.token_group || SecureRandom.uuid

        self.new_refresh_token = Types::RefreshToken.create(
          token: new_refresh_token_text,
          expires_at: now + refresh_token_ttl,
          created_at: now,
          token_group:
        )
      end

      def save_new_refresh_token_on_user
        user.refresh_tokens << refresh_token_entity
      end

      def tokens
        {
          access_token:,
          refresh_token: new_refresh_token
        }
      end
    end
  end
end
