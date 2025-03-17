RSpec.describe Foobara::Auth::Login do
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
      expect(jwt_payload["sub"]).to eq(user.id)
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
        expect(errors.first).to be_a(Foobara::Auth::Login::InvalidPasswordError)
      end
    end

    context "when logging in using username" do
      let(:inputs) do
        { username: user.username, plaintext_password: }
      end

      it "is successful" do
        expect(outcome).to be_success
        expect(result[:access_token]).to be_a(String)
        expect(result[:refresh_token]).to be_a(String)
      end
    end

    context "when logging in using email" do
      let(:inputs) do
        { email: user.email, plaintext_password: }
      end

      it "is successful" do
        expect(outcome).to be_success
        expect(result[:access_token]).to be_a(String)
        expect(result[:refresh_token]).to be_a(String)
      end
    end

    context "when logging in using username_or_email" do
      let(:inputs) do
        { username_or_email:, plaintext_password: }
      end

      context "when using email" do
        let(:username_or_email) { user.email }

        it "is successful" do
          expect(outcome).to be_success
          expect(result[:access_token]).to be_a(String)
          expect(result[:refresh_token]).to be_a(String)
        end
      end

      context "when using username" do
        let(:username_or_email) { user.username }

        it "is successful" do
          expect(outcome).to be_success
          expect(result[:access_token]).to be_a(String)
          expect(result[:refresh_token]).to be_a(String)
        end

        context "when username doesn't exist" do
          let(:username_or_email) { "nonexistent_username" }

          it "is not successful" do
            expect(outcome).to_not be_success
            expect(errors.size).to eq(1)
            expect(errors.first).to be_a(Foobara::Auth::FindUser::UserNotFoundError)
          end
        end
      end
    end

    context "when logging without user id, username, or email" do
      let(:inputs) do
        { plaintext_password: }
      end

      it "is not successful" do
        expect(outcome).to_not be_success
        expect(outcome.errors_hash.keys).to include("runtime.no_user_id_email_or_username_given")
      end
    end
  end
end
