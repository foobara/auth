module Foobara
  module Auth
    class CreateUser < Foobara::Command
      inputs Types::User.attributes_for_create

      result Types::User

      def execute
        create_user

        user
      end

      attr_accessor :user

      def create_user
        self.user = Types::User.create!(inputs)
      end
    end
  end
end
