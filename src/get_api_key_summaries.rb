module Foobara
  module Auth
    class GetApiKeySummaries < Foobara::Command
      inputs do
        user Types::User, :required
      end

      result [Types::ApiKeySummary]

      def execute
        build_summaries

        summaries
      end

      attr_accessor :api_keys, :summaries

      def build_summaries
        self.summaries = user.api_keys.map do |api_key|
          Types::ApiKeySummary.new(
            token_id: api_key.id,
            state: api_key.state,
            expires_at: api_key.expires_at,
            created_at: api_key.created_at
          )
        end
      end
    end
  end
end
