module Foobara
  module Auth
    module Types
      class ApiKeySummary < Foobara::Model
        attributes do
          token_id :string, :required
          state :token_state, :required, default: :needs_approval
          expires_at :datetime, :allow_nil
          created_at :datetime, :required
        end
      end
    end
  end
end
