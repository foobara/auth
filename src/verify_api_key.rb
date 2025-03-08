require "argon2"
require "securerandom"
require "base64"

module Foobara
  module Auth
    class VerifyApiKey < Foobara::Command
      inputs do
        token :string, :required # TODO: we should add a processor that flags an attribute as sensitive so we can scrub
      end
      result :boolean

      depends_on_entity Types::ApiKey

      def execute
        check_for_valid_key

        valid_key?
      end

      attr_accessor :valid_key

      def valid_key?
        !!valid_key
      end

      def check_for_valid_key
        prefix = token[..4]
        hash_for_user = token[5..]

        Types::ApiKey.find_all_by_attribute(:prefix, prefix).each do |key|
          if Argon2::Password.verify_password(hash_for_user, key.hashed_token)
            self.valid_key = true
            break
          end
        end
      end
    end
  end
end
