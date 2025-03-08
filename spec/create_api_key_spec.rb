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
    {}
  end

  def count
    Foobara::Auth::Types::ApiKey.transaction do
      Foobara::Auth::Types::ApiKey.count
    end
  end

  it "is successful" do
    expect {
      expect(outcome).to be_success
    }.to change { count }.from(0).to(1)

    expect(result).to be_a(String)

    api_key = Foobara::Auth::Types::ApiKey.transaction do
      Foobara::Auth::Types::ApiKey.first
    end

    expect(result[0..3]).to eq(api_key.prefix)
  end
end
