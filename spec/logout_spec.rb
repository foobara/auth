RSpec.describe Foobara::Auth::Logout do
  after { Foobara.reset_alls }

  before do
    Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
  end

  let(:command) { described_class.new(inputs) }
  let(:outcome) { command.run }
  let(:result) { outcome.result }
  let(:errors) { outcome.errors }
  let(:errors_hash) { outcome.errors_hash }

  let(:user) do
    Foobara::Auth::CreateUser.run!(username: "Basil", email: "basil@foobara.com", plaintext_password:)
  end
  let(:plaintext_password) { "somepassword" }

  context "when logged in with refresh token" do
    let(:refresh_token) do
      Foobara::Auth::Login.run!(user: user.id, plaintext_password:)[:refresh_token]
    end

    let(:inputs) do
      { refresh_token: }
    end

    it "is successful" do
      expect(outcome).to be_success
      expect(result).to be_nil

      user.class.transaction do
        reloaded_user = Foobara::Auth::Types::User.load(user.id)
        expect(reloaded_user.refresh_tokens.size).to eq(1)
        expect(reloaded_user.refresh_tokens).to all be_inactive
      end
    end
  end
end
