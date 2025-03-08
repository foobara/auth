require_relative "role"

module Foobara
  module Auth
    module Types
      class User < Foobara::Entity
        attributes do
          id :integer, :required
          email :email, :required
          roles [Types::Role], :required, default: []
        end

        primary_key :id
      end
    end
  end
end
