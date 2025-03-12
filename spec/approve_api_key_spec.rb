RSpec.describe Foobara::Auth::ApproveToken do
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
      token: token.id
    }
  end

  let(:user) { Foobara::Auth::CreateUser.run!(username: "Basil", email: "basil@foobara.com") }

  let(:token) do
    Foobara::Auth::CreateApiKey.run!(user: user.id, needs_approval: true)

    Foobara::Auth::Types::Token.transaction do
      Foobara::Auth::Types::Token.first
    end
  end

  it "is successful" do
    key = token

    expect {
      expect(outcome).to be_success
      key = result
    }.to change { key.state }.from(:needs_approval).to(:active)
  end
end
