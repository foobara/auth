module Foobara
  module Auth
    module Types
      class Secret < Foobara::Model
        attributes do
          hashed_secret :string, :required, :sensitive
          parameters :duck, :required
          created_at :datetime, :required
        end
      end
    end
  end
end
