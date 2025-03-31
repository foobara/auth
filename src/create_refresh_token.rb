require "securerandom"

require_relative "create_token"

module Foobara
  module Auth
    class CreateRefreshToken < Foobara::Command
      depends_on CreateToken

      inputs do
        user Types::User
        token_ttl :integer, default: 30 * 60
      end

      result :string, :sensitive_exposed

      def execute
        determine_timestamps
        determine_token_group

        generate_new_refresh_token
        save_new_refresh_token_on_user

        refresh_token_secret
      end

      attr_accessor :expires_at, :refresh_token_record, :token_group, :refresh_token_secret

      def determine_timestamps
        now = Time.now
        self.expires_at = now + token_ttl
      end

      def determine_token_group
        self.token_group = refresh_token_record&.token_group || SecureRandom.uuid
      end

      def generate_new_refresh_token
        result = run_subcommand!(CreateToken, expires_at:, token_group:)

        self.refresh_token_record = result[:token_record]
        self.refresh_token_secret = result[:token_string]
      end

      def save_new_refresh_token_on_user
        # TODO: maybe override #<< on these objects to dirty the entity??
        user.refresh_tokens = [refresh_token_record, *user.refresh_tokens]
      end
    end
  end
end
