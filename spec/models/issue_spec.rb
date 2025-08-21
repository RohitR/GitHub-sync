# frozen_string_literal: true

require "rails_helper"

RSpec.describe Issue, type: :model do
  let(:user) { create(:user) }

  subject { build(:issue, user:) }

  describe "associations" do
    it "belongs to user" do
      assoc = described_class.reflect_on_association(:user)
      expect(assoc).not_to be_nil
      expect(assoc.macro).to eq(:belongs_to)
    end
  end

  describe "enum state" do
    it "defines the correct enum values for state" do
      expect(described_class.states.keys).to match_array(["open", "closed"])
    end
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "is not valid without github_id" do
      subject.github_id = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:github_id]).to include("can't be blank")
    end

    it "enforces uniqueness of github_id" do
      create(:issue, github_id: subject.github_id, user:)
      expect(subject).not_to be_valid
      expect(subject.errors[:github_id]).to include("has already been taken")
    end

    it "is not valid without number" do
      subject.number = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:number]).to include("can't be blank")
    end

    it "validates numericality of number" do
      subject.number = "abc"
      expect(subject).not_to be_valid
      expect(subject.errors[:number]).to include("is not a number")
    end

    it "is not valid without state" do
      subject.state = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:state]).to include("can't be blank")
    end

    it "accepts valid states" do
      subject.state = "open"
      expect(subject).to be_valid
      subject.state = "closed"
      expect(subject).to be_valid
    end

    it "rejects invalid states" do
      expect { subject.state = "invalid" }.to raise_error(ArgumentError)
    end

    it "is not valid without title" do
      subject.title = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:title]).to include("can't be blank")
    end

    it "is not valid without created_at" do
      subject.created_at = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:created_at]).to include("can't be blank")
    end

    it "is not valid without updated_at" do
      subject.updated_at = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:updated_at]).to include("can't be blank")
    end
  end

  describe ".by_state scope" do
    let!(:open_issue) { create(:issue, state: "open", user:) }
    let!(:closed_issue) { create(:issue, state: "closed", user:) }

    it "returns issues with the given state" do
      expect(described_class.by_state("open")).to include(open_issue)
      expect(described_class.by_state("open")).not_to include(closed_issue)
      expect(described_class.by_state("closed")).to include(closed_issue)
      expect(described_class.by_state("closed")).not_to include(open_issue)
    end

    it "returns all issues if state is nil" do
      expect(described_class.by_state(nil)).to include(open_issue, closed_issue)
    end

    it "returns all issues if state is blank" do
      expect(described_class.by_state("")).to include(open_issue, closed_issue)
    end
  end
end
