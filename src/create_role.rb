module Foobara
  module Auth
    class CreateRole < Foobara::Command
      inputs Types::Role.attributes_for_create

      result Types::Role

      def execute
        create_role

        role
      end

      attr_accessor :role

      def create_role
        self.role = Types::Role.create(inputs)
      end
    end
  end
end
