module Foobara
  module Auth
    module Types
      class ApiKey < Foobara::Entity
        State = Foobara::Enumerated.make_module(%i[needs_approval approved rejected])
      end
    end

    foobara_register_type(:state, :symbol, one_of: Types::ApiKey::State)
  end
end
