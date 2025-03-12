module Foobara
  module Auth
    class CreateUser < Foobara::Command
      inputs Types::User.attributes_for_create

      add_inputs do
        plaintext_password :string
      end

      result Types::User

      depends_on SetPassword

      def execute
        create_user

        if password_present?
          set_password
        end

        user
      end

      attr_accessor :user

      def create_user
        self.user = Types::User.create(inputs.except(:plaintext_password))
      end

      def password_present?
        plaintext_password && !plaintext_password.empty?
      end

      def set_password
        run_subcommand!(SetPassword, user:, plaintext_password:)
      end
    end
  end
end
