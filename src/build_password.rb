require "argon2"

module Foobara
  module Auth
    class BuildSecret < Foobara::Command
      inputs do
        secret :string, :required
      end
      result Types::Secret

      def execute
        generate_hashed_secret
        build_secret

        secret_model
      end

      attr_accessor :hashed_secret, :secret_model

      def generate_hashed_secret
        self.hashed_secret = Argon2::Password.create(secret, **argon_params)
      end

      def build_secret
        self.secret_model = Types::Secret.new(
          hashed_secret:,
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
