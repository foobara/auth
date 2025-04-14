require "securerandom"

require_relative "create_token"

module Foobara
  module Auth
    class CreateResetPasswordToken < Foobara::Command
      depends_on CreateToken

      inputs do
        user Types::User, :required
        token_ttl :integer, default: 5 * 60
      end

      result :string, :sensitive_exposed

      def execute
        determine_timestamps

        generate_new_reset_password_token
        save_new_reset_password_token_on_user

        reset_password_token_secret
      end

      attr_accessor :expires_at, :reset_password_token_record, :reset_password_token_secret

      def determine_timestamps
        now = Time.now
        self.expires_at = now + token_ttl
      end

      def generate_new_reset_password_token
        result = run_subcommand!(CreateToken, expires_at:)

        self.reset_password_token_record = result[:token_record]
        self.reset_password_token_secret = result[:token_string]
      end

      def save_new_reset_password_token_on_user
        user.reset_password_token = reset_password_token_record
      end
    end
  end
end
