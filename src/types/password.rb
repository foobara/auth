module Foobara
  module Auth
    module Types
      class Password < Foobara::Model
        attributes do
          hashed_password :string, :required
          parameters :duck, :required
          created_at :datetime, :required
        end
      end
    end
  end
end
