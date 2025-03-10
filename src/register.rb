require_relative "types/user"

module Foobara
  module Auth
    class Register < Foobara::Command
      depends_on CreateUser, SetPassword

      inputs do
        username :string, :required
        email :email, :required
        plaintext_password :string, :required
      end

      result Types::User

      def execute
        create_user
        set_password

        user
      end

      attr_accessor :user

      def create_user
        self.user = run_subcommand!(CreateUser, username:, email:)
      end

      def set_password
        run_subcommand!(SetPassword, user:, plaintext_password:)
      end
    end
  end
end
