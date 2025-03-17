RSpec.describe Foobara::Auth::SetPassword do
  after { Foobara.reset_alls }

  around do |example|
    Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
    Foobara::Auth::Types::User.transaction { example.run }
  end

  let(:command) { described_class.new(inputs) }
  let(:outcome) { command.run }
  let(:result) { outcome.result }
  let(:errors) { outcome.errors }
  let(:errors_hash) { outcome.errors_hash }

  let(:inputs) do
    { user:, plaintext_password: }
  end
  let(:user) { Foobara::Auth::CreateUser.run!(username: "Basil", email: "basil@foobara.com") }
  let(:plaintext_password) { "somepassword" }

  it "is successful" do
    expect(user.password_secret).to be_nil
    expect(outcome).to be_success
    expect(result.password_secret).to be_a(Foobara::Auth::Types::Secret)
  end
end
