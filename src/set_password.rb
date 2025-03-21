module Foobara
  module Auth
    class SetPassword < Foobara::Command
      inputs do
        user Types::User
        plaintext_password :string, :required, :sensitive_exposed
      end
      result Types::User

      depends_on BuildSecret

      # TODO: should we enforce certain password requirements?
      def execute
        build_password
        set_password_on_user

        user
      end

      attr_accessor :password_secret

      def build_password
        self.password_secret = run_subcommand!(BuildSecret, secret: plaintext_password)
      end

      def set_password_on_user
        user.password_secret = password_secret
      end
    end
  end
end
