# frozen_string_literal: true

module Api
  module V1
    class IssuesController < ApplicationController
      def index
        trigger_github_sync_if_needed

        issues = fetch_issues_filtered
        set_pagination_headers(issues)

        render json: issues
      end

      private
        def trigger_github_sync_if_needed
          last_sync_time = Rails.cache.read("last_github_sync")
          if last_sync_time.nil? || last_sync_time < 5.minutes.ago
            GithubSyncJob.perform_later
          end
        end

        def fetch_issues_filtered
          issues = Issue.all.includes(:user)
          if params[:state].present?
            state = params[:state].to_s.downcase
            issues = issues.by_state(state) if %w[open closed].include?(state)
          end
          issues
        end

        def set_pagination_headers(issues_relation)
          response.headers["X-Total-Count"] = issues_relation.count.to_s
        end
    end
  end
end
