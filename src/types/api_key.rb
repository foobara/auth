require_relative "user"

module Foobara
  module Auth
    module Types
      class ApiKey < Foobara::Entity
        attributes do
          id :integer
          token :string, :required, "Base64 representation of the API key", default: -> {
            Base64.strict_encode64(SecureRandom.random_bytes(32))
          }
          user :User, :required
          state :state, :required, default: :needs_approval
          expires_at :datetime
        end

        primary_key :id

        def state_machine
          @state_machine ||= ApiKey::StateMachine.new(owner: self, target_attribute: :state)
        end

        def approve!
          state_machine.approve!
        end

        def reject!
          state_machine.reject!
        end
      end
    end
  end
end
