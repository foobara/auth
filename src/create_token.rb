require "securerandom"
require "base64"

require_relative "build_secret"

module Foobara
  module Auth
    class CreateToken < Foobara::Command
      inputs do
        expires_at :datetime
        token_group :string
        needs_approval :boolean, default: false
      end

      result do
        token_string :string, :required
        token_record Types::Token, :required
      end

      depends_on BuildSecret
      depends_on_entity Types::Token

      def execute
        generate_token_secret
        generate_hashed_secret
        generate_token_id
        construct_token_string
        create_token_record

        unless needs_approval?
          activate_token
        end

        token_string_and_record
      end

      attr_accessor :token_id, :token_secret, :token_string, :hashed_secret, :build_password_params, :token_record

      def generate_token_id
        bytes = SecureRandom.random_bytes(token_id_bytes)

        begin
          token_id = Base64.strict_encode64(bytes)
        end while Types::Token.exists?(token_id)

        self.token_id = token_id
      end

      def generate_token_secret
        bytes = SecureRandom.random_bytes(secret_bytes)
        self.token_secret = Base64.strict_encode64(bytes)
      end

      def secret_bytes
        32
      end

      def generate_hashed_secret
        secret = run_subcommand!(BuildSecret, secret: token_secret)
        self.hashed_secret = secret.hashed_secret
        self.build_password_params = secret.parameters
      end

      def create_token_record
        attributes = {
          hashed_secret:,
          id: token_id,
          token_parameters: build_password_params.merge(other_params),
          created_at: Time.now
        }

        if expires_at
          attributes[:expires_at] = expires_at
        end

        if token_group
          attributes[:token_group] = token_group
        end

        self.token_record = Types::Token.create(attributes)
      end

      def needs_approval?
        needs_approval
      end

      def activate_token
        token_record.approve!
      end

      def construct_token_string
        self.token_string = "#{token_id}_#{token_secret}"
      end

      def token_string_and_record
        {
          token_string:,
          token_record:
        }
      end

      def other_params
        { secret_bytes:, token_id_bytes: }
      end

      def token_id_bytes
        6
      end
    end
  end
end
