RSpec.describe Foobara::Auth::ResetPassword do
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
  let(:old_password) { plaintext_password }
  let(:new_password) { "somenewpassword" }
  let(:reset_password_token_secret) do
    Foobara::Auth::CreateResetPasswordToken.run!(user: user.id)
  end

  context "when using a reset password token" do
    let(:inputs) do
      { reset_password_token_secret:, new_password: }
    end

    it "is successful and we can verify with the new password after resetting" do
      expect(
        Foobara::Auth::VerifyPassword.run!(user: user.id, plaintext_password: old_password)
      ).to be true
      expect(
        Foobara::Auth::VerifyPassword.run!(user: user.id, plaintext_password: new_password)
      ).to be false

      expect(outcome).to be_success
      expect(result).to be_a(Foobara::Auth::Types::User)

      expect(
        Foobara::Auth::VerifyPassword.run!(user: user.id, plaintext_password: old_password)
      ).to be false
      expect(
        Foobara::Auth::VerifyPassword.run!(user: user.id, plaintext_password: new_password)
      ).to be true
    end

    it "marks the original refresh token as used" do
      reset_password_token_secret

      reloaded_user = Foobara::Auth::FindUser.run!(id: user.id)
      reset_token_id = reloaded_user.reset_password_token.id

      expect {
        expect(outcome).to be_success
      }.to change {
        Foobara::Auth::Types::User.transaction do
          Foobara::Auth::Types::Token.load(reset_token_id).inactive?
        end
      }.from(false).to(true)
    end

    context "with an invalid refresh token" do
      let(:inputs) do
        { reset_password_token_secret: invalid_token, new_password: }
      end
      let(:invalid_token) do
        text = reset_password_token_secret.dup
        text[-5] = text[-5] == "x" ? "y" : "x"
        text
      end

      it "fails with appropriate error" do
        expect(outcome).to_not be_success
        expect(outcome.errors_hash).to include("runtime.invalid_reset_password_token")
      end
    end

    context "when the reset password token has been replaced" do
      it "fails with the expected error" do
        reset_password_token_secret
        Foobara::Auth::CreateResetPasswordToken.run!(user: user.id)

        expect(outcome).to_not be_success
        expect(outcome.errors_hash.keys).to include("runtime.user_not_found_for_reset_token")
      end
    end
  end

  context "when using the old password to reset" do
    let(:inputs) do
      { user: user.id, old_password:, new_password: }
    end

    it "is successful and we can verify with the new password after resetting" do
      expect(
        Foobara::Auth::VerifyPassword.run!(user: user.id, plaintext_password: old_password)
      ).to be true
      expect(
        Foobara::Auth::VerifyPassword.run!(user: user.id, plaintext_password: new_password)
      ).to be false

      expect(outcome).to be_success
      expect(result).to be_a(Foobara::Auth::Types::User)

      expect(
        Foobara::Auth::VerifyPassword.run!(user: user.id, plaintext_password: old_password)
      ).to be false
      expect(
        Foobara::Auth::VerifyPassword.run!(user: user.id, plaintext_password: new_password)
      ).to be true
    end

    context "when the old password is bad" do
      let(:inputs) do
        { user: user.id, old_password: "badpassword", new_password: }
      end

      it "gives the expected error" do
        expect(outcome).to_not be_success
        expect(outcome.errors_hash.keys).to include("runtime.incorrect_old_password")
      end
    end

    context "when omitting the user" do
      let(:inputs) do
        { old_password:, new_password: }
      end

      it "gives the expected error" do
        expect(outcome).to_not be_success
        expect(outcome.errors_hash.keys).to include("runtime.user_not_given")
      end
    end
  end

  context "when giving everything" do
    let(:inputs) do
      { user: user.id, old_password:, new_password:, reset_password_token_secret: }
    end

    it "gives the expected error" do
      expect(outcome).to_not be_success
      expect(outcome.errors_hash.keys).to include("runtime.both_password_reset_token_and_old_password_given")
    end
  end

  context "when only giving the user and new_password" do
    let(:inputs) do
      { user: user.id, new_password: }
    end

    it "gives the expected error" do
      expect(outcome).to_not be_success
      expect(outcome.errors_hash.keys).to include("runtime.no_password_reset_token_or_old_password_given")
    end
  end
end
