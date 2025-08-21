# frozen_string_literal: true

class GithubSyncJob < ApplicationJob
  queue_as :default

  def perform
    GithubIssueService.sync_issues
    # Store last sync time for rate limiting
    Rails.cache.write("last_github_sync", Time.current, expires_in: 5.minutes)
  end
end
