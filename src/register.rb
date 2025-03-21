require_relative "types/user"

module Foobara
  module Auth
    class Register < Foobara::Command
      depends_on CreateUser, SetPassword

      inputs do
        username :string, :required
        email :email, :required
        plaintext_password :string, :allow_nil, :sensitive_exposed
      end

      result Types::User

      def execute
        create_user
        if password?
          set_password
        end

        user
      end

      attr_accessor :user

      def create_user
        self.user = run_subcommand!(CreateUser, username:, email:)
      end

      def password?
        plaintext_password && !plaintext_password.empty?
      end

      def set_password
        run_subcommand!(SetPassword, user:, plaintext_password:)
      end
    end
  end
end
