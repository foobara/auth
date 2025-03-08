module Foobara
  module Auth
    module Types
      class ApiKey < Foobara::Entity
        attributes do
          id :integer
          hashed_token :string, :required
          prefix :string, :required
          token_length :integer, :required
          state :state, :required, default: :needs_approval
          token_parameters :duck, :required
          expires_at :datetime, :allow_nil
          created_at :datetime, :required
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
