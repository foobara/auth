require_relative "role"

module Foobara
  module Auth
    module Types
      class User < Foobara::Entity
        attributes do
          id :integer
          username :string, :required
          email :email, :required
          roles [Types::Role], :required, default: []
          api_key [Types::ApiKey], :required, default: []
          current_password_hash :string, :allow_nil
        end

        primary_key :id
      end
    end
  end
end
