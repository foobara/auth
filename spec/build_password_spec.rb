RSpec.describe Foobara::Auth::BuildSecret do
  let(:command) { described_class.new(inputs) }
  let(:outcome) { command.run }
  let(:result) { outcome.result }
  let(:errors) { outcome.errors }
  let(:errors_hash) { outcome.errors_hash }

  let(:inputs) do
    { secret: }
  end

  let(:secret) { "somepassword" }

  it "is successful" do
    expect(outcome).to be_success

    expect(result).to be_a(Foobara::Auth::Types::Secret)
  end
end
