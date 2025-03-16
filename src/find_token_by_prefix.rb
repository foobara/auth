require_relative "verify_token"

module Foobara
  module Auth
    class FindTokenRecordFromTokenString < Foobara::Command
      inputs do
        token_string :string, :required
      end

      result Types::Token

      depends_on VerifyToken

      def execute
        find_token

        token
      end

      attr_accessor :token

      def find_token
        prefix = token[..4]

        tokens = Types::Token.find_all_by_attribute(:prefix, prefix)

        if tokens.size == 1
          self.token = tokens.first
        elsif tokens.size > 1
          self.token = Types::Token.find_all_by_attribute(:prefix, prefix).find do |key|
            Argon2::Password.verify_password(hash_for_user, key.hashed_token)
          end
        end
      end
    end
  end
end
