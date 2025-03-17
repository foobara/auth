module Foobara
  module Auth
    class FindUser < Foobara::Command
      class UserNotFoundError < Foobara::RuntimeError
        context do
          id :integer
          username :string
          email :email
        end

        def message
          "No user found for #{context}"
        end
      end

      inputs do
        id :integer
        username :string
        email :email
      end

      result Types::User

      def execute
        load_user

        user
      end

      attr_accessor :user

      def load_user
        self.user = Types::User.find_by(inputs)

        unless user
          add_runtime_error(UserNotFoundError.new(context: inputs))
        end
      end
    end
  end
end
