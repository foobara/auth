module Foobara
  module Auth
    module Types
      class Token < Foobara::Entity
        class StateMachine < Foobara::StateMachine
          set_transition_map({
                               needs_approval: {
                                 approve: :approved,
                                 reject: :rejected
                               },
                               approved: {
                                 revoke: :revoked
                               }
                             })
        end
      end
    end
  end
end
