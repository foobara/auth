require_relative "role"
require_relative "password"

module Foobara
  module Auth
    module Types
      class User < Foobara::Entity
        attributes do
          id :integer
          username :string, :required
          email :email, :required
          roles [Types::Role], default: []
          api_keys [Types::ApiKey], default: []
          password Types::Password, :allow_nil
        end

        primary_key :id
      end
    end
  end
end
