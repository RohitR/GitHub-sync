# frozen_string_literal: true

require "rails_helper"
require "httparty"

RSpec.describe GithubIssueService, type: :service do
  let(:http_client) { class_double("HTTParty") }
  let(:last_sync_time) { 2.days.ago.change(usec: 0) }
  let(:per_page) { GithubIssueService::PER_PAGE }

  let(:issue_data) do
    Array.new(per_page) do |i|
      {
        "id" => 10_000 + i,
        "number" => 100 + i,
        "state" => "open",
        "title" => "Issue #{i}",
        "body" => "Body #{i}",
        "created_at" => "2025-08-10T10:00:00Z",
        "updated_at" => "2025-08-11T10:00:00Z",
        "user" => {
          "id" => 5000 + i,
          "login" => "userlogin#{i}",
          "avatar_url" => "http://avatar.url",
          "type" => "User",
          "html_url" => "http://user.url"
        }
      }
    end
  end

  before do
    create(:issue, github_updated_at: last_sync_time, number: 1_000_000)
    ActiveJob::Base.queue_adapter = :test
  end

  it "fetches paginated issues and upserts issues and users" do
    allow(Issue).to receive(:maximum).with(:github_updated_at).and_return(last_sync_time)

    first_page_response = instance_double(HTTParty::Response, success?: true, body: issue_data.to_json)
    second_page_response = instance_double(HTTParty::Response, success?: true, body: "[]")

    expect(http_client).to receive(:get).with(
      GithubIssueService::BASE_URL,
      query: hash_including(page: 1),
      headers: GithubIssueService::USER_AGENT
    ).and_return(first_page_response)

    expect(http_client).to receive(:get).with(
      GithubIssueService::BASE_URL,
      query: hash_including(page: 2),
      headers: GithubIssueService::USER_AGENT
    ).and_return(second_page_response)

    expect {
      GithubIssueService.sync_issues(http_client:)
    }.to change { Issue.count }.by(per_page).and change { User.count }.by(per_page)

    issue = Issue.find_by(github_id: 10_000)
    User.find_by(github_id: 5000)

    expect(issue.title).to eq("Issue 0")
    expect(issue.user.login).to eq("userlogin0")
  end

  it "logs error and returns empty array when HTTP request fails" do
    allow(Rails.logger).to receive(:error)


    allow(Issue).to receive(:maximum).and_return(nil)
    failed_response = instance_double(HTTParty::Response, success?: false, body: "error", code: 500)
    allow(http_client).to receive(:get).and_return(failed_response)

    expect(Rails.logger).to receive(:error).with(/Failed to fetch GitHub issues/).at_least(:once)

    expect {
      GithubIssueService.sync_issues(http_client:)
    }.not_to change { Issue.count }
  end
end
