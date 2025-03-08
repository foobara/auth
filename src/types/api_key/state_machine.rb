module Foobara
  module Auth
    module Types
      class ApiKey < Foobara::Entity
        class StateMachine < Foobara::StateMachine
          set_transition_map({
                               needs_approval: {
                                 approve: :approved,
                                 reject: :rejected
                               }
                             })
        end
      end
    end
  end
end
