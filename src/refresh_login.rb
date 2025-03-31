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

      depends_on CreateRefreshToken, VerifyToken, BuildAccessToken
      depends_on_entities Types::Token

      inputs do
        refresh_token :string, :required, :sensitive
        access_token_ttl :integer, default: 30 * 60
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

        generate_access_token
        generate_new_refresh_token

        tokens
      end

      attr_accessor :access_token, :new_refresh_token, :expires_at, :refresh_token_record,
                    :refresh_token_id, :refresh_token_secret

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

      def generate_access_token
        self.access_token = run_subcommand!(BuildAccessToken, user:, token_ttl: access_token_ttl)
      end

      def user
        @user ||= Types::User.that_owns(refresh_token_record, "refresh_tokens")
      end

      def generate_new_refresh_token
        self.new_refresh_token = run_subcommand!(CreateRefreshToken, user:, token_ttl: refresh_token_ttl)
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
