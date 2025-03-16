require_relative "verify_secret"

module Foobara
  module Auth
    class VerifyToken < Foobara::Command
      class InactiveTokenError < Foobara::RuntimeError
        context do
          state Types::Token::State, :required
        end

        def message
          "Expected token to be active but it is #{state}"
        end
      end

      inputs do
        # TODO: we should add a processor that flags an attribute as sensitive so we can scrub
        token_string :string, :required
        token_record Types::Token, "Instead of finding a persisted token, check against a specific token record"
      end

      result do
        verified :boolean, :required
        token_record Types::Token, :required
      end

      depends_on VerifySecret

      def execute
        determine_token_id_and_hashed_secret

        unless token_record?
          load_token_record
        end

        validate_token_is_active
        verify_hashed_secret_against_token_record

        verified_and_token_record
      end

      attr_accessor :verified, :token_id, :secret
      attr_writer :token_record_to_verify_against

      def token_record_to_verify_against
        @token_record_to_verify_against || token_record
      end

      def token_record?
        !!token_record
      end

      def determine_token_id_and_hashed_secret
        self.token_id, self.secret = token_string.split("_")
      end

      def check_against_specific_token?
        !!token_record
      end

      def load_token_record
        self.token_record_to_verify_against = Types::Token.load(token_id)
        # TODO: handle no record found...
      end

      def verify_hashed_secret_against_token_record
        hashed_secret = token_record_to_verify_against.hashed_secret

        self.verified = Argon2::Password.verify_password(secret, hashed_secret)
      end

      def validate_token_is_active
        unless token_record_to_verify_against.active?
          add_runtime_error(InactiveTokenError, state: token_record_to_verify_against.current_state)
        end
      end

      def verified_and_token_record
        {
          verified:,
          token_record: token_record_to_verify_against
        }
      end
    end
  end
end
