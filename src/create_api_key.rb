module Foobara
  module Auth
    class CreateApiKey < Foobara::Command
      inputs Types::ApiKey.attributes_for_create

      result Types::ApiKey

      def execute
        create_api_key

        api_key
      end

      attr_accessor :api_key

      def create_api_key
        self.api_key = Auth::ApiKey.create(attributes_for_create)
      end
    end
  end
end
