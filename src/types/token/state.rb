module Foobara
  module Auth
    module Types
      class Token < Foobara::Entity
        State = Foobara::Enumerated.make_module(%i[needs_approval approved rejected revoked])
      end
    end

    foobara_register_type(:state, :symbol, one_of: Types::Token::State)
  end
end
