module Foobara
  module Auth
    class ApproveToken < Foobara::Command
      inputs do
        token_record Types::Token, :required
      end

      result Types::Token

      def execute
        approve_token

        token_record
      end

      def approve_token
        token_record.approve!
      end
    end
  end
end
