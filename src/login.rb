require "jwt"
require "securerandom"

require_relative "create_token"
require_relative "verify_password"
require_relative "verify_token"

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

      depends_on CreateToken, VerifyPassword, FindUser

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
        # TODO: DRY these 5 up
        determine_timestamps
        generate_access_token
        determine_token_group
        generate_new_refresh_token
        save_new_refresh_token_on_user

        tokens
      end

      attr_accessor :access_token, :new_refresh_token, :now, :expires_at, :token_group, :user_to_login

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

      def determine_timestamps
        self.now = Time.now
        self.expires_at = now + token_ttl
      end

      def generate_access_token
        payload = { sub: user_to_login.id, exp: expires_at.to_i }

        self.access_token = JWT.encode(payload, jwt_secret, "HS256")
      end

      def jwt_secret
        jwt_secret_text = ENV.fetch("JWT_SECRET", nil)

        unless jwt_secret_text
          # :nocov:
          raise "You must set the JWT_SECRET environment variable"
          # :nocov:
        end

        jwt_secret_text
      end

      def determine_token_group
        self.token_group = SecureRandom.uuid
      end

      def generate_new_refresh_token
        self.new_refresh_token = run_subcommand!(CreateToken, expires_at:, token_group:)
      end

      def save_new_refresh_token_on_user
        # TODO: maybe override #<< on these objects to dirty the entity??
        user_to_login.refresh_tokens = [new_refresh_token[:token_record], *user_to_login.refresh_tokens]
      end

      def tokens
        {
          access_token:,
          refresh_token: new_refresh_token[:token_string]
        }
      end
    end
  end
end
