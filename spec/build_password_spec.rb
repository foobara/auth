RSpec.describe Foobara::Auth::BuildPassword do
  let(:command) { described_class.new(inputs) }
  let(:outcome) { command.run }
  let(:result) { outcome.result }
  let(:errors) { outcome.errors }
  let(:errors_hash) { outcome.errors_hash }

  let(:inputs) do
    { plaintext_password: }
  end

  let(:plaintext_password) { "somepassword" }

  it "is successful" do
    expect(outcome).to be_success

    expect(result).to be_a(Foobara::Auth::Types::Password)
  end
end
