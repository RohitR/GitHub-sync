# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Issues", type: :request do
  let!(:user) { create(:user) }
  let!(:open_issue) { create(:issue, state: "open", user:) }
  let!(:closed_issue) { create(:issue, state: "closed", user:) }

  describe "GET /api/issues" do
    it "enqueues GithubSyncJob if last sync is nil or older than 5 minutes" do
      expect {
        get api_issues_path
      }.to have_enqueued_job(GithubSyncJob)
    end

    it "does not enqueue GithubSyncJob if last sync is within 5 minutes" do
      allow(Rails.cache).to receive(:read).with("last_github_sync").and_return(4.minutes.ago)

      expect {
        get api_issues_path
      }.not_to have_enqueued_job(GithubSyncJob)
    end

    it "returns all issues and sets X-Total-Count header" do
      get api_issues_path
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(Issue.count)
      expect(response.headers["X-Total-Count"]).to eq(Issue.count.to_s)
      expect(json.first).to have_key("user")
      expect(json.first["user"]).to have_key("login")
    end

    context "with state filter" do
      it "returns only open issues if state=open" do
        get api_issues_path, params: { state: "open" }
        json = JSON.parse(response.body)
        expect(json.all? { |i| i["state"] == "open" }).to be true
      end

      it "returns only closed issues if state=closed" do
        get api_issues_path, params: { state: "closed" }
        json = JSON.parse(response.body)
        expect(json.all? { |i| i["state"] == "closed" }).to be true
      end

      it "ignores invalid state values and returns all issues" do
        get api_issues_path, params: { state: "invalid" }
        json = JSON.parse(response.body)
        expect(json.length).to eq(Issue.count)
      end

      it "handles state param case insensitively" do
        get api_issues_path, params: { state: "OPEN" }
        json = JSON.parse(response.body)
        expect(json.all? { |i| i["state"] == "open" }).to be true
      end
    end
  end
end
