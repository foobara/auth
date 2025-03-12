module Foobara
  module Auth
    module Types
      class Token < Foobara::Entity
        attributes do
          id :integer
          hashed_token :string, :required
          prefix :string, :required
          token_length :integer, :required
          state :state, :required, default: :needs_approval
          token_parameters :duck, :required
          token_group :string, :allow_nil
          expires_at :datetime, :allow_nil
          created_at :datetime, :required
        end

        primary_key :id

        def state_machine
          @state_machine ||= StateMachine.new(owner: self, target_attribute: :state)
        end

        def approve!
          state_machine.approve!
        end

        def use_up!
          state_machine.use_up!
        end

        def inactive?
          state_machine.current_state == State::INACTIVE
        end
      end
    end
  end
end
