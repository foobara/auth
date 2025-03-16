RSpec.describe Foobara::Auth::VerifyToken do
  after { Foobara.reset_alls }

  before do
    Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
  end

  let(:api_key) { Foobara::Auth::CreateApiKey.run!(user: user.id) }
  let(:user) { Foobara::Auth::CreateUser.run!(username: "Basil", email: "basil@foobara.com") }

  let(:inputs) do
    { token_string: api_key }
  end

  let(:command) { described_class.new(inputs) }
  let(:outcome) { command.run }
  let(:result) { outcome.result }
  let(:errors) { outcome.errors }
  let(:errors_hash) { outcome.errors_hash }

  it "is successful" do
    expect(outcome).to be_success
    expect(result[:verified]).to be true

    # let's make sure a bad key doesn't work
    bad_key = api_key.dup
    bad_key[-5] = bad_key[-5] == "x" ? "y" : "x"

    expect(described_class.run!(token_string: bad_key)[:verified]).to be false
  end
end
