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
  end
end
