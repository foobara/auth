module Foobara
  module Auth
    module Types
      class Token < Foobara::Entity
        attributes do
          id :string, :required
          hashed_secret :string, :required
          state :token_state, :required, default: :needs_approval
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

        def expire!
          state_machine.expire!
        end

        def inactive?
          state_machine.current_state == State::INACTIVE
        end

        def active?
          state_machine.current_state == State::ACTIVE
        end
      end
    end
  end
end
