module Foobara
  module Auth
    class ApproveToken < Foobara::Command
      inputs do
        token Types::Token, :required
      end

      result Types::Token

      def execute
        approve_token

        token
      end

      def approve_token
        token.approve!
      end
    end
  end
end
