module Foobara
  module Auth
    module Types
      class Token < Foobara::Entity
        State = Foobara::Enumerated.make_module(StateMachine.states)
      end
    end

    foobara_register_type(:token_state, :symbol, one_of: Types::Token::State)
  end
end
