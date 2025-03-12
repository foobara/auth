module Foobara
  module Auth
    class FindUser < Foobara::Command
      inputs do
        id :integer, :required
      end
      result Types::User

      def execute
        load_user

        user
      end

      attr_accessor :user

      def load_user
        self.user = Types::User.load(id)
      end
    end
  end
end
