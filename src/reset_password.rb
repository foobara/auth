module Foobara
  module Auth
    class ResetPassword < Foobara::Command
      class NoPasswordResetTokenOrOldPasswordGivenError < Foobara::RuntimeError
        context({})
        message "Must give either a password reset token or an old password"
      end

      class BothPasswordResetTokenAndOldPasswordGivenError < Foobara::RuntimeError
        context({})
        message "Cannot give both a password reset token and an old password"
      end

      class IncorrectOldPasswordError < Foobara::RuntimeError
        context({})
        message "Incorrect old password"
      end

      class InvalidResetPasswordTokenError < Foobara::RuntimeError
        context({}) # TODO: make this the default
        message "Invalid password reset token"
      end

      class UserNotGivenError < Foobara::RuntimeError
        context({})
        message "Must give a user if giving an old password to reset password"
      end

      class UserNotFoundForResetTokenError < Foobara::RuntimeError
        context({}) # TODO: make this the default?
        message "No user found for reset password token"
      end

      inputs do
        user Types::User
        old_password :string, :sensitive_exposed
        reset_password_token_secret :string, :sensitive_exposed
        new_password :string, :sensitive, :required
      end
      result Types::User

      depends_on BuildSecret, VerifyPassword, VerifyToken

      # TODO: should we enforce certain password requirements?
      def execute
        if old_password_given?
          verify_old_password
        else
          verify_and_use_up_password_reset_token
          load_user
        end

        build_new_password
        set_password_on_user

        user
      end

      def validate
        if old_password_given?
          unless user
            add_runtime_error(UserNotGivenError)
          end
          if reset_password_token_given?
            add_runtime_error(BothPasswordResetTokenAndOldPasswordGivenError)
          end
        else
          unless reset_password_token_given?
            add_runtime_error(NoPasswordResetTokenOrOldPasswordGivenError)
          end
        end
      end

      attr_accessor :password_secret, :reset_password_token_record
      attr_writer :user

      def old_password_given?
        !!old_password
      end

      def reset_password_token_given?
        !!reset_password_token_secret
      end

      def verify_old_password
        unless run_subcommand!(VerifyPassword, user:, plaintext_password: old_password)
          add_runtime_error(IncorrectOldPasswordError)
        end
      end

      def verify_and_use_up_password_reset_token
        verified_result = run_subcommand!(VerifyToken, token_string: reset_password_token_secret)

        unless verified_result[:verified]
          add_runtime_error(InvalidResetPasswordTokenError)
        end

        self.reset_password_token_record = verified_result[:token_record]
        reset_password_token_record.use_up!
      end

      def load_user
        self.user = Types::User.that_owns(reset_password_token_record, "reset")

        unless user
          add_runtime_error(UserNotFoundForResetTokenError)
        end
      end

      def user
        @user || inputs[:user]
      end

      def build_new_password
        self.password_secret = run_subcommand!(BuildSecret, secret: new_password)
      end

      def set_password_on_user
        user.password_secret = password_secret
      end
    end
  end
end
