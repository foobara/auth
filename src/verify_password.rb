require_relative "verify_token"

module Foobara
  module Auth
    class VerifyPassword < Foobara::Command
      inputs do
        user Types::User, :required
        # TODO: we should add a processor that flags an attribute as sensitive so we can scrub
        plaintext_password :string, :required, :sensitive
      end
      result :boolean

      depends_on VerifySecret

      def execute
        # TODO: result in error if no password set yet?
        check_for_valid_password

        valid_password?
      end

      attr_accessor :valid_password

      def valid_password?
        !!valid_password
      end

      def check_for_valid_password
        hashed_secret = user.password_secret.hashed_secret

        self.valid_password = if hashed_secret
                                run_subcommand!(VerifySecret, secret: plaintext_password, hashed_secret:)
                              end
      end
    end
  end
end
