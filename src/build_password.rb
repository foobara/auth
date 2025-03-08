module Foobara
  module Auth
    class BuildPassword < Foobara::Command
      inputs do
        plaintext_password :string, :required
      end
      result Types::Password

      def execute
        generate_hashed_password
        build_password

        password
      end

      attr_accessor :hashed_password, :password

      def generate_hashed_password
        self.hashed_password = Argon2::Password.create(plaintext_password, **argon_params)
      end

      def build_password
        self.password = Types::Password.new(
          hashed_password:,
          parameters: argon_params.merge(other_params),
          created_at: Time.now
        )
      end

      def argon_params
        {
          t_cost: 2,
          m_cost: 16,
          parallelism: 1,
          type: :argon2id
        }
      end

      def other_params
        { method: :argon2id }
      end
    end
  end
end
