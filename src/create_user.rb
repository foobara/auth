module Foobara
  module Auth
    class CreateUser < Foobara::Command
      inputs Types::User.attributes_for_create

      add_inputs do
        user_id :integer, :allow_nil
        plaintext_password :string, :sensitive_exposed
      end

      result Types::User

      depends_on SetPassword

      possible_input_error :username, :already_in_use
      possible_input_error :email, :already_in_use

      def execute
        create_user

        if password_present?
          set_password
        end

        user
      end

      def validate
        validate_username_is_unique
        if email
          validate_email_is_unique
        end
      end

      attr_accessor :user

      def validate_username_is_unique
        if Types::User.find_by(username:)
          add_input_error(input: :username, symbol: :already_in_use)
        end
      end

      def validate_email_is_unique
        if Types::User.find_by(email:)
          add_input_error(input: :email, symbol: :already_in_use)
        end
      end

      def create_user
        inputs = self.inputs.except(:user_id, :plaintext_password)

        if user_id
          inputs[:id] = user_id
        end

        self.user = Types::User.create(inputs)
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
