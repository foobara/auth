RSpec.describe Foobara::Auth::RefreshLogin do
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

  context "when authenticating with refresh token" do
    let(:refresh_token_text) do
      Foobara::Auth::Login.run!(user: user.id, plaintext_password:)[:refresh_token]
    end

    let(:inputs) do
      {
        user: user.id,
        refresh_token_text:
      }
    end

    it "is successful" do
      expect(outcome).to be_success
      expect(result[:access_token]).to be_a(String)
      expect(result[:refresh_token]).to be_a(String)
    end

    it "marks the original refresh token as used" do
      refresh_token_text

      reloaded_user = Foobara::Auth::FindUser.run!(id: user.id)
      original_token_id = reloaded_user.refresh_tokens.first.id

      expect {
        outcome
      }.to change {
        Foobara::Auth::Types::User.transaction do
          Foobara::Auth::Types::Token.load(original_token_id).inactive?
        end
      }.from(false).to(true)
    end

    context "with an invalid refresh token" do
      let(:inputs) do
        { user: user.id, refresh_token_text: invalid_token }
      end
      let(:invalid_token) do
        text = refresh_token_text.dup
        text[-5] = text[-5] == "x" ? "y" : "x"
        text
      end

      it "fails with appropriate error" do
        expect(outcome).to_not be_success
        expect(outcome.errors_hash).to include("runtime.invalid_refresh_token")
      end
    end

    context "with a token that doesn't belong to the user" do
      let(:inputs) do
        { user: user.id, refresh_token_text: other_user_token }
      end
      let(:other_user) do
        Foobara::Auth::CreateUser.run!(username: "Barbara", email: "barbara@foobara.com", plaintext_password:)
      end
      let(:other_user_token) do
        Foobara::Auth::Login.run!(user: other_user.id, plaintext_password:)[:refresh_token]
      end

      it "fails with appropriate error" do
        expect(outcome).to_not be_success
        expect(outcome.errors_hash).to include("runtime.refresh_token_not_owned_by_user")
      end
    end
  end
end
