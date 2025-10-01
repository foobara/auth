require "securerandom"
require "base64"

require_relative "build_secret"
require_relative "create_token"

module Foobara
  module Auth
    class DeleteApiKey < Foobara::Command
      inputs do
        token Types::Token, :required
      end

      def execute
        remove_api_key_from_user
        delete_token

        nil
      end

      def load_records
        super
        self.user = Types::User.that_owns(token, :api_keys)
      end

      attr_accessor :user

      # should Foobara do this automatically? Or at least support it? Similar to CASCADE in SQL
      def remove_api_key_from_user
        api_keys = user.api_keys

        if api_keys.include?(token)
          user.api_keys = api_keys - [token]
        else
          # :nocov:
          raise "User has no such api key"
          # :nocov:
        end
      end

      def delete_token
        token.hard_delete!
      end
    end
  end
end
