RSpec.describe Foobara::Auth::VerifyPassword do
  after { Foobara.reset_alls }

  around do |example|
    Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
    Foobara::Auth::Types::User.transaction { example.run }
  end

  let(:api_key) { Foobara::Auth::CreateApiKey.run! }
  let(:command) { described_class.new(inputs) }
  let(:outcome) { command.run }
  let(:result) { outcome.result }
  let(:errors) { outcome.errors }
  let(:errors_hash) { outcome.errors_hash }

  let(:inputs) do
    { user:, plaintext_password: password_to_check }
  end
  let(:user) { Foobara::Auth::CreateUser.run!(username: "Basil", email: "basil@foobara.com") }
  let(:plaintext_password) { "somepassword" }
  let(:password_to_check) { plaintext_password }

  before do
    Foobara::Auth::SetPassword.run!(user:, plaintext_password:)
  end

  context "when the password is correct" do
    it "is true" do
      expect(outcome).to be_success
      expect(result).to be true
    end
  end

  context "when the password is incorrect" do
    let(:password_to_check) { "wrong" }

    it "is false" do
      expect(outcome).to be_success
      expect(result).to be false
    end
  end
end
