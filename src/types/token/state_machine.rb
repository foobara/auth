module Foobara
  module Auth
    module Types
      class Token < Foobara::Entity
        class StateMachine < Foobara::StateMachine
          set_transition_map({
                               needs_approval: {
                                 approve: :active,
                                 reject: :rejected
                               },
                               active: {
                                 revoke: :revoked,
                                 use_up: :inactive,
                                 expire: :expired
                               }
                             })
        end
      end
    end
  end
end
