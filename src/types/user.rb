require_relative "role"
require_relative "secret"

module Foobara
  module Auth
    module Types
      class User < Foobara::Entity
        attributes do
          id :integer
          username :string, :required
          email :email, :allow_nil
          roles [Types::Role], default: []
          api_keys [Types::Token], :sensitive, default: []
          refresh_tokens [Types::Token], :sensitive, default: []
          password_secret Types::Secret, :sensitive, :allow_nil
          reset_password_token Types::Token, :sensitive, :allow_nil
        end

        primary_key :id
      end
    end
  end
end
