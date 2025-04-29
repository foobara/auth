require_relative "types/user"

module Foobara
  module Auth
    # TODO: should raise error if username or email already in use!
    class Register < Foobara::Command
      depends_on CreateUser, SetPassword

      inputs do
        user_id :integer, :allow_nil
        username :string, :required
        email :email, :allow_nil
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
        inputs = { username:, email: }

        if user_id
          inputs[:user_id] = user_id
        end

        self.user = run_subcommand!(CreateUser, inputs)
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
