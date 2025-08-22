# frozen_string_literal: true

Sidekiq::Cron::Job.create(
  name: "Github Issues Sync - every 30min",
  cron: "*/30 * * * *",
  class: "GithubSyncJob"
)
