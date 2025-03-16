require "jwt"
require "securerandom"

require_relative "create_token"
require_relative "verify_password"
require_relative "verify_token"

module Foobara
  module Auth
    class CreateLoginTokens < Foobara::Command
      class MustProvideEitherTokenOrPasswordError < Foobara::RuntimeError
        context({})
        message "You must provide either a refresh token or a password"
      end

      class InvalidRefreshTokenError < Foobara::RuntimeError
        context refresh_token_id: :integer
        message "Invalid refresh token"
      end

      class InvalidPasswordError < Foobara::RuntimeError
        context({})
        message "Invalid password"
      end

      depends_on CreateToken, VerifyPassword, VerifyToken

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
          determine_refresh_token_id_and_secret
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
        save_new_refresh_token_on_user

        tokens
      end

      attr_accessor :access_token, :new_refresh_token, :now, :expires_at, :refresh_token,
                    :refresh_token_id, :refresh_token_secret

      def validate
        super

        if (refresh_token_text.nil? || refresh_token_text.empty?) &&
           (plaintext_password.nil? || plaintext_password.empty?)
          add_runtime_error(MustProvideEitherTokenOrPasswordError)
        end
      end

      def determine_refresh_token_id_and_secret
        self.refresh_token_id, self.refresh_token_secret = refresh_token_text.split("_")
      end

      def load_refresh_token
        self.refresh_token = user.refresh_tokens.find do |refresh_token|
          refresh_token.id == refresh_token_id
        end
      end

      def verify_refresh_token
        valid = refresh_token && run_subcommand!(VerifyToken, token_string: refresh_token_text)

        unless valid
          add_runtime_error(InvalidRefreshTokenError)
        end
      end

      def mark_refresh_token_as_used
        refresh_token.use_up!
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

      def generate_new_refresh_token
        token_group = refresh_token&.token_group || SecureRandom.uuid
        token = run_subcommand!(CreateToken, expires_at:, token_group:)

        self.new_refresh_token = token
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
