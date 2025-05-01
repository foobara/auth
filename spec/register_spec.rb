RSpec.describe Foobara::Auth::Register do
  after { Foobara.reset_alls }

  before do
    Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
  end

  let(:command) { described_class.new(inputs) }
  let(:outcome) { command.run }
  let(:result) { outcome.result }
  let(:errors) { outcome.errors }

  let(:inputs) do
    {
      username:,
      email:,
      plaintext_password:
    }
  end
  let(:username) { "Barbara" }
  let(:email) { "bar@baz.com" }
  let(:plaintext_password) { "password" }

  def user_count
    Foobara::Auth::Types::User.transaction do
      Foobara::Auth::Types::User.count
    end
  end

  def verify_password
    Foobara::Auth::VerifyPassword.run!(user: result, plaintext_password:)
  end

  describe "#run" do
    it "creates a user with expected attributes" do
      expect {
        expect(outcome).to be_success
      }.to change { user_count }.from(0).to(1)

      expect(result).to be_a(Foobara::Auth::Types::User)
      expect(result.username).to eq(username)
      expect(result.email).to eq(email)

      expect(verify_password).to be true
    end

    context "when specifying a user_id" do
      let(:inputs) do
        super().merge(user_id: 1000)
      end

      it "creates a user with that id" do
        expect(outcome).to be_success
        expect(result.id).to eq(1000)
      end
    end

    context "when username is already in use" do
      let(:other_user) do
        described_class.run!(username:,
                             email: "foo@foo.com",
                             plaintext_password:)
      end

      it "does not create the user and gives the expected result" do
        other_user

        user_class = Foobara::Auth::Types::User

        expect(user_class.transaction { user_class.count }).to eq(1)

        expect(outcome).to_not be_success
        # TODO: I don't think I like that this is from create_user instead of register_user
        expect(outcome.errors_hash.keys).to eq(["foobara::auth::create_user>data.username.already_in_use"])

        expect(user_class.transaction { user_class.count }).to eq(1)
      end
    end

    context "when email is already in use" do
      let(:other_user) do
        described_class.run!(username: "Basil",
                             email:,
                             plaintext_password:)
      end

      it "does not create the user and gives the expected result" do
        other_user

        user_class = Foobara::Auth::Types::User

        expect(user_class.transaction { user_class.count }).to eq(1)

        expect(outcome).to_not be_success
        # TODO: I don't think I like that this is from create_user instead of register_user
        expect(outcome.errors_hash.keys).to eq(["foobara::auth::create_user>data.email.already_in_use"])

        expect(user_class.transaction { user_class.count }).to eq(1)
      end
    end
  end
end
