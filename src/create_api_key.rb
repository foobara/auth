require "securerandom"
require "base64"

require_relative "build_secret"
require_relative "create_token"

module Foobara
  module Auth
    class CreateApiKey < Foobara::Command
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

        self.token = result[:token_record]
        self.key_for_user = result[:token_string]
      end

      def associate_token_with_user
        user.api_keys = [*user.api_keys, token]
      end
    end
  end
end
