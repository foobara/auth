RSpec.describe Foobara::Auth::CreateRole do
  after { Foobara.reset_alls }

  let(:command) { described_class.new(inputs) }
  let(:outcome) { command.run }
  let(:result) { outcome.result }
  let(:errors) { outcome.errors }
  let(:errors_hash) { outcome.errors_hash }

  let(:inputs) do
    { symbol: }
  end

  let(:symbol) { :some_role }

  it "is successful", :focus do
    expect(outcome).to be_success
    expect(result).to eq("bar")
  end
end
