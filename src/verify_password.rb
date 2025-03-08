require "argon2"

module Foobara
  module Auth
    class VerifyPassword < Foobara::Command
      inputs do
        user Types::User, :required
        # TODO: we should add a processor that flags an attribute as sensitive so we can scrub
        plaintext_password :string, :required
      end
      result :boolean

      depends_on_entity Types::ApiKey

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
        hashed_password = user.password.hashed_password
        self.valid_password = if hashed_password
                                Argon2::Password.verify_password(plaintext_password, user.password.hashed_password)
                              end
      end
    end
  end
end
