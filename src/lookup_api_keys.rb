module Foobara
  module Auth
    class LookupApiKeys < Foobara::Command
      inputs Types::ApiKey.attributes_for_find_by

      result [Types::ApiKey]

      depends_on_entities Types::ApiKey

      def execute
        lookup_api_keys

        api_keys
      end

      attr_accessor :api_keys

      def lookup_api_keys
        self.api_keys = Types::ApiKey.find_by(inputs)
      end
    end
  end
end
