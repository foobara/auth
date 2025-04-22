require "timecop"

RSpec.describe Foobara::Auth::VerifyAccessToken do
  after { Foobara.reset_alls }

  before do
    Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
  end

  let(:access_token) { Foobara::Auth::Login.run!(user: user.id, plaintext_password:)[:access_token] }
  let(:user) { Foobara::Auth::CreateUser.run!(username: "Basil", email: "basil@foobara.com", plaintext_password:) }
  let(:plaintext_password) { "somepassword" }

  let(:inputs) do
    { access_token: }
  end

  let(:command) { described_class.new(inputs) }
  let(:outcome) { command.run }
  let(:result) { outcome.result }
  let(:errors) { outcome.errors }
  let(:errors_hash) { outcome.errors_hash }

  it "is successful" do
    expect(outcome).to be_success
    expect(result[:verified]).to be true
    expect(result[:payload]["sub"]).to eq(user.id)
    expect(result[:payload]["exp"]).to be_an(Integer)

    # let's make sure a bad key doesn't work
    bad_key = access_token.dup
    bad_key[-5] = bad_key[-5] == "x" ? "y" : "x"

    # TODO: should this not be success instead??
    bad_token_result = described_class.run!(access_token: bad_key)
    expect(bad_token_result[:verified]).to be false
    expect(bad_token_result[:failure_reason]).to eq("cannot_verify")
  end

  context "when token is expired" do
    it "is not successful and expires the token" do
      access_token

      Timecop.travel(Time.now + (1000 * 24 * 60 * 60)) do
        # TODO: should be failure instead??
        expect(outcome).to be_success
        expect(result[:verified]).to be false
        expect(result[:failure_reason]).to eq("expired")
      end
    end
  end

  context "when token is malformed junk" do
    let(:access_token) do
      super()
      "junk"
    end

    it "is not successful" do
      expect(outcome).to be_success
      expect(result[:verified]).to be false
      expect(result[:failure_reason]).to eq("invalid")
    end
  end
end
