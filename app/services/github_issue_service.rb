# frozen_string_literal: true

require "httparty"

class GithubIssueService
  BASE_URL = "https://api.github.com/repos/storyblok/storyblok/issues"
  USER_AGENT = { "User-Agent" => "StoryBlokAPI" }.freeze
  PER_PAGE = 100

  class << self
    def sync_issues(http_client: HTTParty)
      last_sync = last_github_update_time
      page = 1

      loop do
        issues = fetch_issues(page, last_sync, http_client)
        break if issues.empty?

        issues.each { |issue_data| upsert_issue_and_user(issue_data) }

        break if issues.size < PER_PAGE
        page += 1
      end
    end

    private
      def last_github_update_time
        Issue.maximum(:github_updated_at)
      end

      def fetch_issues(page, last_sync, http_client)
        params = {
          state: "all",
          sort: "updated",
          direction: "asc",
          per_page: PER_PAGE,
          page:
        }
        params[:since] = last_sync.utc.iso8601 if last_sync

        response = http_client.get(BASE_URL, query: params, headers: USER_AGENT)

        raise response.body unless response.success?

        JSON.parse(response.body)
      rescue StandardError => e
        Rails.logger.error("Failed to fetch GitHub issues (page #{page}): #{e.message}")
        []
      end

      def upsert_issue_and_user(issue_data)
        user = find_or_create_user(issue_data["user"])
        Issue.upsert(
          {
            github_id: issue_data["id"],
            number: issue_data["number"],
            state: issue_data["state"],
            title: issue_data["title"],
            body: issue_data["body"],
            created_at: issue_data["created_at"],
            updated_at: issue_data["updated_at"],
            github_updated_at: issue_data["updated_at"],
            user_id: user.id
          },
          unique_by: :github_id
        )
      end

      def find_or_create_user(user_data)
        user = User.find_or_initialize_by(github_id: user_data["id"])
        user.assign_attributes(
          login: user_data["login"],
          avatar_url: user_data["avatar_url"],
          user_type: user_data["type"],
          url: user_data["html_url"]
        )
        user.save! if user.changed?
        user
      end
  end
end
