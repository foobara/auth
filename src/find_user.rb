module Foobara
  module Auth
    class FindUser < Foobara::Command
      class UserNotFoundError < Foobara::RuntimeError
        context Types::User.attributes_for_find_by
        def message
          "No user found for #{context}"
        end
      end

      inputs Types::User.attributes_for_find_by
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
