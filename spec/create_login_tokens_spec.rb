RSpec.describe Foobara::Auth::CreateLoginTokens do
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

  context "when authenticating with password" do
    let(:inputs) do
      { user: user.id, plaintext_password: }
    end

    it "is successful" do
      expect(outcome).to be_success
      expect(result[:access_token]).to be_a(String)
      expect(result[:refresh_token]).to be_a(String)
    end

    it "creates a JWT with correct values" do
      expect(outcome).to be_success
      jwt_payload = JWT.decode(result[:access_token], ENV.fetch("JWT_SECRET", nil), true, algorithm: "HS256").first
      expect(jwt_payload["user_id"]).to eq(user.id)
      expect(jwt_payload["username"]).to eq(user.username)
      expect(jwt_payload["exp"]).to be > Time.now.to_i
    end

    it "adds a refresh token to the user" do
      expect {
        outcome
      }.to change {
        user_id = user.id
        Foobara::Auth::Types::User.transaction do
          reloaded_user = Foobara::Auth::Types::User.load(user_id)
          reloaded_user.refresh_tokens.count
        end
      }.from(0).to(1)
    end

    context "with incorrect password" do
      let(:inputs) do
        { user: user, plaintext_password: "wrong_password" }
      end

      it "fails with appropriate error" do
        expect(outcome).to_not be_success
        expect(errors.first).to be_a(Foobara::Auth::CreateLoginTokens::InvalidPasswordError)
      end
    end
  end

  context "when authenticating with refresh token" do
    let(:refresh_token_text) do
      described_class.run!(user: user.id, plaintext_password:)[:refresh_token]
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
        { user:, refresh_token_text: "invalid_token" }
      end

      it "fails with appropriate error" do
        expect(outcome).to_not be_success
        expect(outcome.errors_hash).to include("runtime.invalid_refresh_token")
      end
    end
  end
end
