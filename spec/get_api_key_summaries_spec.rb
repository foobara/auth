RSpec.describe Foobara::Auth::GetApiKeySummaries do
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
    { user: user }
  end

  let(:user) { Foobara::Auth::CreateUser.run!(username: "Basil", email: "basil@foobara.com") }

  context "when there are api keys" do
    let(:api_keys) do
      (0..3).map do
        Foobara::Auth::CreateApiKey.run!(user:)
      end
    end

    it "returns summary models" do
      api_keys

      expect(outcome).to be_success

      expect(result.size).to eq(api_keys.size)

      result.map(&:token_id).each do |prefix_string|
        expect(prefix_string.size).to be > 5
        expect(api_keys.any? { |k| k.start_with?(prefix_string) }).to be true
      end
    end
  end
end
