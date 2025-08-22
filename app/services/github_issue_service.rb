# frozen_string_literal: true

require "circuitbox"

class GithubIssueService
  BASE_URL = "https://api.github.com/repos/storyblok/storyblok/issues"
  USER_AGENT = { "User-Agent" => "StoryBlokAPI" }.freeze
  PER_PAGE = 100

  CIRCUITBOX_OPTIONS = {
    exceptions: [StandardError],
    sleep_window: 60,
    volume_threshold: 5,
    error_threshold: 50,
    timeout_seconds: 10
  }

  class << self
    def sync_issues(http_client: HTTParty)
      last_sync = last_github_update_time
      page = 1

      loop do
        issues = fetch_issues(page, last_sync, http_client)
        break if issues.nil? || issues.empty?

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
        breaker = Circuitbox.circuit(:github_api, CIRCUITBOX_OPTIONS)

        Rails.logger.info("Circuit is currently #{breaker.open? ? 'OPEN' : 'CLOSED'}")

        breaker.run do
          params = {
            state: "all",
            sort: "updated",
            direction: "asc",
            per_page: PER_PAGE,
            page:
          }
          params[:since] = last_sync.utc.iso8601 if last_sync

          response = http_client.get(BASE_URL, query: params, headers: USER_AGENT,
  timeout: CIRCUITBOX_OPTIONS[:timeout_seconds])

          raise response.body unless response.success?

          JSON.parse(response.body)
        end
      rescue Circuitbox::Error => e
        Rails.logger.error("GitHub API circuit open or error: #{e.message}")
        [] # Return empty array when circuit is open or fails
      rescue StandardError => e
        Rails.logger.error("Failed to fetch GitHub issues (page #{page}): #{e.message}")
        []
      end

      def upsert_issue_and_user(issue_data)
        # https://docs.github.com/en/rest/issues/issues?apiVersion=2022-11-28
        return if issue_data.key?("pull_request")

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
