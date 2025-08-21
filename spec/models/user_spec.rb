# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  let(:valid_attributes) do
    {
      github_id: 12345,
      login: "testuser",
      avatar_url: "https://example.com/avatar.jpg",
      user_type: "User",
      url: "https://github.com/testuser"
    }
  end

  it "is valid with valid attributes" do
    user = User.new(valid_attributes)
    expect(user).to be_valid
  end

  it "requires github_id" do
    user = User.new(valid_attributes.except(:github_id))
    expect(user).not_to be_valid
  end

  it "requires unique github_id" do
    User.create!(valid_attributes)
    user = User.new(valid_attributes)
    expect(user).not_to be_valid
  end
end
