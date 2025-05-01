RSpec.describe Foobara::Auth::AuthenticateWithApiKey do
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

  context "when authenticating with api key" do
    let(:api_key) do
      Foobara::Auth::CreateApiKey.run!(user: user.id)
    end

    let(:inputs) do
      { api_key: }
    end

    it "is successful" do
      expect(outcome).to be_success
      expect(result.size).to eq(2)
      auth_user, token = result
      expect(auth_user).to be_a(Foobara::Auth::Types::User)
      expect(token).to be_a(Foobara::Auth::Types::Token)
      expect(auth_user.username).to eq(user.username)
    end

    context "with an invalid api key" do
      let(:inputs) do
        { api_key: invalid_token }
      end
      let(:invalid_token) do
        text = api_key.dup
        text[-5] = text[-5] == "x" ? "y" : "x"
        text
      end

      it "fails with appropriate error" do
        expect(outcome).to_not be_success
        expect(outcome.errors_hash).to include("runtime.invalid_api_key")
      end
    end

    context "with a key that doesn't exist" do
      let(:inputs) do
        { api_key: "doesnotexist" }
      end

      it "fails with appropriate error" do
        expect(outcome).to_not be_success
        expect(outcome.errors_hash).to include("runtime.api_key_does_not_exist")
      end
    end
  end
end
