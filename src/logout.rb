module Foobara
  module Auth
    class Logout < Foobara::Command
      class InvalidRefreshTokenError < Foobara::RuntimeError
        context refresh_token_id: :string
        message "Invalid refresh token"
      end

      depends_on VerifyToken
      depends_on_entity Types::Token
      depends_on_entity Types::User

      inputs do
        refresh_token :string, :allow_nil
      end

      # TODO: support nil result type in typescript remote command generator
      result :duck

      def execute
        if refresh_token?
          determine_refresh_token_id_and_secret
          load_refresh_token_record
          verify_refresh_token
          # Delete it instead maybe?
          mark_refresh_token_as_used
        end

        nil
      end

      attr_accessor :refresh_token_record, :refresh_token_id, :refresh_token_secret

      def refresh_token?
        !!refresh_token
      end

      def determine_refresh_token_id_and_secret
        self.refresh_token_id, self.refresh_token_secret = refresh_token.split("_")
      end

      def load_refresh_token_record
        self.refresh_token_record = Types::Token.load(refresh_token_id)
      end

      def verify_refresh_token
        valid = run_subcommand!(VerifyToken, token_string: refresh_token)

        unless valid[:verified]
          # :nocov:
          add_runtime_error(InvalidRefreshTokenError.new(context: { refresh_token_id: }))
          # :nocov:
        end
      end

      def mark_refresh_token_as_used
        refresh_token_record.use_up!
      end
    end
  end
end
