module Foobara
  module Auth
    class Logout < Foobara::Command
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

          if refresh_token_record?
            verify_refresh_token
            # Delete it instead maybe?
            mark_refresh_token_as_used
          end
        end

        nil
      end

      attr_accessor :refresh_token_record, :refresh_token_id, :refresh_token_secret, :token_verified

      def refresh_token?
        !!refresh_token
      end

      def determine_refresh_token_id_and_secret
        self.refresh_token_id, self.refresh_token_secret = refresh_token.split("_")
      end

      def load_refresh_token_record
        self.refresh_token_record = Types::Token.load(refresh_token_id)
      rescue Foobara::Entity::NotFoundError
        nil
      end

      def refresh_token_record?
        refresh_token_record
      end

      def verify_refresh_token
        valid = run_subcommand!(VerifyToken, token_string: refresh_token)

        self.token_verified = valid[:verified]
      end

      def mark_refresh_token_as_used
        refresh_token_record.use_up!
      end
    end
  end
end
