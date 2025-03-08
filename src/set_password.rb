require "argon2"

module Foobara
  module Auth
    class SetPassword < Foobara::Command
      inputs do
        user Types::User
        plaintext_password :string, :required
      end
      result Types::User

      depends_on BuildPassword

      # TODO: should we enforce certain password requirements?
      def execute
        build_password
        set_password_on_user

        user
      end

      attr_accessor :password

      def build_password
        self.password = run_subcommand!(BuildPassword, plaintext_password:)
      end

      def set_password_on_user
        user.password = password
      end
    end
  end
end
