require "argon2"
require "securerandom"
require "base64"

module Foobara
  module Auth
    class CreateApiKey < Foobara::Command
      result :string

      depends_on_entity Types::ApiKey

      def execute
        generate_prefix
        generate_raw_key
        generate_key_for_user
        generate_hashed_key
        create_api_key
        prepend_prefix

        key_for_user
      end

      attr_accessor :raw_key, :key_for_user, :hashed_key, :prefix

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
        self.hashed_key = Argon2::Password.create(key_for_user, **argon_params)
      end

      def create_api_key
        Types::ApiKey.create(
          hashed_token: hashed_key,
          prefix: prefix,
          token_length: key_for_user.length,
          state: :approved,
          token_parameters: argon_params.merge(other_params),
          expires_at: nil,
          created_at: Time.now
        )
      end

      def prepend_prefix
        self.key_for_user = "#{prefix}#{key_for_user}"
      end

      def argon_params
        {
          t_cost: 2,
          m_cost: 16,
          parallelism: 1,
          type: :argon2id
        }
      end

      def other_params
        { bytes:, prefix_length:, prefix_bytes: }
      end

      def prefix_length
        4
      end

      def prefix_bytes
        3
      end
    end
  end
end
