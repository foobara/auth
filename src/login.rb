module Foobara
  module Auth
    class Login < Foobara::Command
      class InvalidPasswordError < Foobara::RuntimeError
        context({})
        message "Invalid password"
      end

      class NoUserIdEmailOrUsernameGivenError < Foobara::RuntimeError
        context({})
        message "No user id, email, or username given"
      end

      depends_on VerifyPassword, FindUser, BuildAccessToken, CreateRefreshToken

      inputs do
        user Types::User, :allow_nil
        username :string, :allow_nil
        email :string, :allow_nil
        username_or_email :string, :allow_nil
        plaintext_password :string, :required, :sensitive_exposed
        # Configure these instead of defaulting them here?
        token_ttl :integer, default: 30 * 60
        refresh_token_ttl :integer, default: 7 * 24 * 60 * 60
      end

      result do
        access_token :string, :required, :sensitive_exposed
        refresh_token :string, :required, :sensitive_exposed
      end

      def execute
        find_user_to_login
        verify_password
        generate_access_token
        generate_new_refresh_token

        tokens
      end

      attr_accessor :access_token, :refresh_token_text, :user_to_login

      def find_user_to_login
        if user
          self.user_to_login = user
        elsif username
          self.user_to_login = run_subcommand!(FindUser, username:)
        elsif email
          self.user_to_login = run_subcommand!(FindUser, email:)
        elsif username_or_email
          begin
            self.user_to_login = run_subcommand!(FindUser, username: username_or_email)
          rescue Halt
            # I'm a bit nervous about rescuing Halt and clearing the errors, but I'm more nervous bout
            # introducing a #run_subcommand method.
            if error_collection.size == 1 && error_collection.errors.first.is_a?(FindUser::UserNotFoundError) &&
               username_or_email.include?("@")
              error_collection.clear
              self.user_to_login = run_subcommand!(FindUser, email: username_or_email)
            else
              raise
            end
          end
        else
          add_runtime_error(NoUserIdEmailOrUsernameGivenError)
        end
      end

      def verify_password
        unless run_subcommand!(VerifyPassword, user: user_to_login, plaintext_password:)
          add_runtime_error(InvalidPasswordError)
        end
      end

      def generate_access_token
        self.access_token = run_subcommand!(BuildAccessToken, user: user_to_login)
      end

      def generate_new_refresh_token
        self.refresh_token_text = run_subcommand!(CreateRefreshToken, user: user_to_login)
      end

      def tokens
        {
          access_token:,
          refresh_token: refresh_token_text
        }
      end
    end
  end
end
