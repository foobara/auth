require_relative "verify_token"

module Foobara
  module Auth
    class AuthenticateWithApiKey < Foobara::Command
      class InvalidApiKeyError < Foobara::RuntimeError
        context({})
        message "Invalid api key"
      end

      class ApiKeyDoesNotExistError < Foobara::RuntimeError
        context({})
        message "No such key"
      end

      depends_on VerifyToken
      depends_on_entities Types::Token

      inputs do
        api_key :string, :required, :sensitive
        access_token_ttl :integer, default: 30 * 60
        api_key_ttl :integer, default: 7 * 24 * 60 * 60
      end

      result [Types::User, Types::Token]

      def execute
        determine_api_key_id_and_secret
        load_api_key_record
        verify_api_key

        load_user

        user_and_credential
      end

      attr_accessor :expires_at, :api_key_record, :api_key_id, :api_key_secret, :user

      def determine_api_key_id_and_secret
        self.api_key_id, self.api_key_secret = api_key.split("_")
      end

      def load_api_key_record
        self.api_key_record = Types::Token.load(api_key_id)
      rescue Foobara::Entity::NotFoundError
        add_runtime_error(ApiKeyDoesNotExistError)
      end

      def verify_api_key
        valid = run_subcommand!(VerifyToken, token_string: api_key)

        unless valid[:verified]
          add_runtime_error(InvalidApiKeyError)
        end
      end

      def load_user
        self.user ||= Types::User.that_owns(api_key_record, "api_keys")
      end

      def user_and_credential
        [user, api_key_record]
      end
    end
  end
end
