RSpec.describe Foobara::Auth::CreateRole do
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
    { symbol: }
  end

  let(:symbol) { :some_role }

  it "is successful" do
    expect(outcome).to be_success
    expect(result).to be_a(Foobara::Auth::Types::Role)
    expect(result.symbol).to eq(:some_role)
  end
end
