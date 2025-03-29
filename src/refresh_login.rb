require "jwt"
require "securerandom"

require_relative "create_token"
require_relative "verify_token"

module Foobara
  module Auth
    class RefreshLogin < Foobara::Command
      class InvalidRefreshTokenError < Foobara::RuntimeError
        context refresh_token_id: :string
        message "Invalid refresh token"
      end

      class RefreshTokenNotOwnedByUser < Foobara::RuntimeError
        context refresh_token_id: :string
        message "This refresh token is not owned by this user"
      end

      depends_on CreateToken, VerifyToken
      depends_on_entities Types::Token

      inputs do
        refresh_token :string, :required, :sensitive
        # Can we get these TTLs off of the refresh token?
        token_ttl :integer, default: 30 * 60
        refresh_token_ttl :integer, default: 7 * 24 * 60 * 60
      end

      result do
        access_token :string, :required, :sensitive_exposed
        refresh_token :string, :required, :sensitive_exposed
      end

      def execute
        determine_refresh_token_id_and_secret
        load_refresh_token_record
        verify_refresh_token
        # Delete it instead maybe?
        mark_refresh_token_as_used
        determine_timestamps
        determine_token_group

        generate_access_token
        generate_new_refresh_token
        save_new_refresh_token_on_user

        tokens
      end

      attr_accessor :access_token, :new_refresh_token, :now, :expires_at, :refresh_token_record,
                    :refresh_token_id, :refresh_token_secret, :token_group

      def determine_refresh_token_id_and_secret
        self.refresh_token_id, self.refresh_token_secret = refresh_token.split("_")
      end

      def load_refresh_token_record
        self.refresh_token_record = Types::Token.load(refresh_token_id)
      end

      def verify_refresh_token
        valid = run_subcommand!(VerifyToken, token_string: refresh_token)

        unless valid[:verified]
          add_runtime_error(InvalidRefreshTokenError.new(context: { refresh_token_id: }))
        end
      end

      def mark_refresh_token_as_used
        refresh_token_record.use_up!
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

      def user
        @user ||= Types::User.that_owns(refresh_token_record, "refresh_tokens")
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
        self.token_group = refresh_token_record&.token_group || SecureRandom.uuid
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
