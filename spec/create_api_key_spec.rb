RSpec.describe Foobara::Auth::CreateApiKey do
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
    { user: user.id }
  end

  let(:user) { Foobara::Auth::CreateUser.run!(username: "Basil", email: "basil@foobara.com") }

  def count
    Foobara::Auth::Types::Token.transaction do
      Foobara::Auth::Types::Token.count
    end
  end

  it "is successful" do
    expect {
      expect(outcome).to be_success
    }.to change { count }.from(0).to(1)

    expect(result).to be_a(String)

    api_key = Foobara::Auth::Types::Token.transaction do
      reloaded_user = Foobara::Auth::Types::User.load(user.id)
      expect(reloaded_user.api_keys.count).to eq(1)
      key = reloaded_user.api_keys.first
      Foobara::Auth::Types::Token.load(key)
    end

    expect(result[..7]).to eq(api_key.id)
  end
end
