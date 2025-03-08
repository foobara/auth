module Foobara
  module Auth
    module Types
      class Role < Foobara::Entity
        attributes do
          # TODO: support non-integer primary keys
          id :integer, :required
          symbol :symbol, :required
        end

        primary_key :id
      end
    end
  end
end
