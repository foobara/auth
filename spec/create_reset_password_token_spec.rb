RSpec.describe Foobara::Auth::CreateResetPasswordToken do
  after { Foobara.reset_alls }

  before do
    Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
  end

  let(:command) { described_class.new(inputs) }
  let(:outcome) { command.run }
  let(:result) { outcome.result }
  let(:errors) { outcome.errors }
  let(:errors_hash) { outcome.errors_hash }

  let(:user) do
    Foobara::Auth::CreateUser.run!(username: "Basil", email: "basil@foobara.org", plaintext_password:)
  end
  let(:plaintext_password) { "somepassword" }

  let(:inputs) do
    { user: user.id }
  end

  it "sets the user's reset_password_token" do
    user_id = user.id

    expect {
      expect(outcome).to be_success
    }.to change {
      Foobara::Auth::Types::User.transaction do
        Foobara::Auth::Types::User.load(user_id).reset_password_token&.id
      end
    }
  end
end
