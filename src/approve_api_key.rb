module Foobara
  module Auth
    class ApproveApiKey < Foobara::Command
      inputs do
        api_key Types::ApiKey, :required
      end

      result Types::ApiKey

      def execute
        approve_api_key

        api_key
      end

      def approve_api_key
        api_key.approve!
      end
    end
  end
end
