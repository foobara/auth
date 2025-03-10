RSpec.describe Foobara::Auth::ApproveApiKey do
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
    {
      api_key: api_key.id
    }
  end

  let(:user) { Foobara::Auth::CreateUser.run!(username: "Basil", email: "basil@foobara.com") }

  let(:api_key) do
    Foobara::Auth::CreateApiKey.run!(user: user.id)

    Foobara::Auth::Types::ApiKey.transaction do
      Foobara::Auth::Types::ApiKey.first
    end
  end

  it "is successful" do
    key = api_key
    expect {
      expect(outcome).to be_success
      key = result
    }.to change { key.state }.from(:needs_approval).to(:approved)
  end
end
