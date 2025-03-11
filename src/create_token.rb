require "securerandom"
require "base64"

require_relative "build_password"

module Foobara
  module Auth
    class CreateToken < Foobara::Command
      result do
        key_for_user :string, :required
        token Types::Token, :required
      end

      depends_on BuildPassword
      depends_on_entity Types::Token

      def execute
        generate_prefix
        generate_raw_key
        generate_key_for_user
        generate_hashed_key
        create_api_key
        prepend_prefix

        key_for_user_and_token
      end

      attr_accessor :raw_key, :key_for_user, :hashed_key, :prefix, :build_password_params, :token

      def generate_prefix
        bytes = SecureRandom.hex(prefix_bytes)
        self.prefix = Base64.strict_encode64(bytes)[0..prefix_length - 1]
      end

      def generate_raw_key
        self.raw_key = SecureRandom.hex(bytes)
      end

      def bytes
        24
      end

      def generate_key_for_user
        self.key_for_user = Base64.strict_encode64(raw_key)
      end

      def generate_hashed_key
        password = run_subcommand!(BuildPassword, plaintext_password: key_for_user)
        self.hashed_key = password.hashed_password
        self.build_password_params = password.parameters
      end

      def create_api_key
        self.token = Types::Token.create(
          hashed_token: hashed_key,
          prefix: prefix,
          token_length: key_for_user.length,
          token_parameters: build_password_params.merge(other_params),
          expires_at: nil,
          created_at: Time.now
        )
      end

      def prepend_prefix
        self.key_for_user = "#{prefix}#{key_for_user}"
      end

      def key_for_user_and_token
        {
          key_for_user:,
          token:
        }
      end

      def other_params
        { bytes:, prefix_length:, prefix_bytes: }
      end

      def prefix_length
        5
      end

      def prefix_bytes
        4
      end
    end
  end
end
