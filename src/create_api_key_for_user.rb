require "securerandom"
require "base64"

require_relative "build_password"
require_relative "create_token"

module Foobara
  module Auth
    class CreateApiKeyForUser < Foobara::Command
      inputs do
        user Types::User, :required
        needs_approval :boolean, default: false
      end
      result :string

      depends_on CreateToken
      depends_on_entity Types::Token

      def execute
        create_token
        associate_token_with_user

        key_for_user
      end

      attr_accessor :token, :key_for_user

      def create_token
        result = run_subcommand!(CreateToken, needs_approval:)

        self.token = result[:token]
        self.key_for_user = result[:key_for_user]
      end

      def associate_token_with_user
        user.api_keys = [*user.api_keys, token]
      end
    end
  end
end
