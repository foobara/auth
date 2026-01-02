RSpec.describe Foobara::Auth::DeleteApiKey do
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
    { token: token_id_to_delete }
  end

  let(:user) { Foobara::Auth::CreateUser.run!(username: "Basil", email: "basil@foobara.org") }

  context "when there are api keys" do
    let(:api_keys) do
      (0..4).map do
        Foobara::Auth::CreateApiKey.run!(user:)
      end
    end
    let(:api_key_summaries) do
      Foobara::Auth::GetApiKeySummaries.run!(user:)
    end
    let(:token_id_to_delete) { api_key_summaries[2].token_id }

    def token_count
      Foobara::Auth::Types::Token.transaction do
        Foobara::Auth::Types::Token.count
      end
    end

    it "deletes the api key from the user" do
      api_keys

      expect(Foobara::Auth::GetApiKeySummaries.run!(user:).size).to be(5)
      expect(Foobara::Auth::FindUser.run!(id: user.id).api_keys.map(&:id)).to include(token_id_to_delete)

      expect {
        expect(outcome).to be_success
      }.to change { token_count }.by(-1)

      expect(Foobara::Auth::FindUser.run!(id: user.id).api_keys.map(&:id)).to_not include(token_id_to_delete)
      expect(Foobara::Auth::GetApiKeySummaries.run!(user:).size).to be(4)
    end
  end
end
