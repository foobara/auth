module Foobara
  module Auth
    module Types
      class Role < Foobara::Entity
        attributes do
          id :integer
          symbol :symbol, :required
        end

        primary_key :id
      end
    end
  end
end
