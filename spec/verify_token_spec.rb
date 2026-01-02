RSpec.describe Foobara::Auth::VerifyToken do
  after { Foobara.reset_alls }

  before do
    Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
  end

  let(:api_key) { Foobara::Auth::CreateApiKey.run!(user: user.id) }
  let(:api_key_id) { api_key.split("_").first }
  let(:user) { Foobara::Auth::CreateUser.run!(username: "Basil", email: "basil@foobara.org") }

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

  context "when token is expired" do
    before do
      api_key
      Foobara::Auth::Types::Token.transaction do
        key = Foobara::Auth::Types::Token.load(api_key_id)
        key.expires_at = Time.now - 100
      end
    end

    it "is not successful and expires the token" do
      expect(outcome).to_not be_success
      expect(outcome.errors_hash.keys).to include("runtime.expired_token")
      Foobara::Auth::Types::Token.transaction do
        key = Foobara::Auth::Types::Token.load(api_key_id)
        expect(key.state_machine.current_state).to eq(Foobara::Auth::Types::Token::State::EXPIRED)
      end
    end
  end

  context "when token is inactivated" do
    before do
      api_key
      Foobara::Auth::Types::Token.transaction do
        key = Foobara::Auth::Types::Token.load(api_key_id)
        key.state_machine.revoke!
      end
    end

    it "is not successful" do
      expect(outcome).to_not be_success
      expect(outcome.errors_hash.keys).to include("runtime.inactive_token")
    end
  end

  context "when token doesn't exist" do
    it "is not successful" do
      api_key_id

      Foobara::Auth::Types::Token.transaction do
        api_key = Foobara::Auth::Types::Token.load(api_key_id)
        api_key.hard_delete!
      end

      expect(outcome).to_not be_success
      expect(outcome.errors_hash.keys).to include("runtime.token_does_not_exist")
    end
  end
end
