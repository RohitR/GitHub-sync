# frozen_string_literal: true

module Api
  module V1
    class IssuesController < ApplicationController
      def index
        trigger_github_sync_if_needed

        issues = fetch_issues_filtered.order(created_at: :desc).page(page).per(per_page)
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
          if issue_params[:state].present?
            state = issue_params[:state].to_s.downcase
            issues = issues.by_state(state) if %w[open closed].include?(state)
          end
          issues
        end

        def set_pagination_headers(paginated_issues)
          response.headers["X-Total-Count"] = paginated_issues.total_count.to_s
        end

        def issue_params
          params.permit(:state, :page, :per_page)
        end

        def page
          issue_params[:page].present? ? issue_params[:page].to_i : 1
        end

        def per_page
          max_per_page = 100
          requested = issue_params[:per_page].to_i
          requested > 0 ? [requested, max_per_page].min : 20
        end
    end
  end
end
