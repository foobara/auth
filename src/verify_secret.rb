require "argon2"

module Foobara
  module Auth
    class VerifySecret < Foobara::Command
      inputs do
        secret :string, :required # TODO: we should add a processor that flags an attribute as sensitive so we can scrub
        hashed_secret :string, :required, :sensitive
      end

      result :boolean

      def execute
        verify_secret_against_hashed_secret

        verified?
      end

      attr_accessor :verified

      def verified?
        !!verified
      end

      def verify_secret_against_hashed_secret
        self.verified = Argon2::Password.verify_password(secret, hashed_secret)
      end
    end
  end
end
