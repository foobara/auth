require_relative "role"
require_relative "secret"

module Foobara
  module Auth
    module Types
      class User < Foobara::Entity
        attributes do
          id :integer
          username :string, :required
          email :email, :required
          roles [Types::Role], default: []
          api_keys [Types::Token], default: []
          refresh_tokens [Types::Token], default: []
          password_secret Types::Secret, :allow_nil
        end

        primary_key :id
      end
    end
  end
end
