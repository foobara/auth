RSpec.describe Foobara::Auth::CreateUser do
  after { Foobara.reset_alls }

  before do
    Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
  end

  let(:command) { described_class.new(inputs) }
  let(:outcome) { command.run }
  let(:result) { outcome.result }
  let(:errors) { outcome.errors }
  let(:errors_hash) { outcome.errors_hash }

  let(:inputs) do
    { username:, email: }
  end
  let(:username) { "Basil" }
  let(:email) { "basil@foobara.com" }

  it "is successful" do
    expect(outcome).to be_success
    expect(result).to be_a(Foobara::Auth::Types::User)

    expect(result.username).to eq(username)
    expect(result.email).to eq(email)
  end
end
