# GitHub Issues Sync Service

This Rails service fetches issues from the [Storyblok GitHub repository](https://github.com/storyblok/storyblok/issues) and stores them in the local database for querying via API.

## Features

- Efficiently fetches GitHub issues with pagination.
- Synchronizes linked user data.
- Uses a circuit breaker pattern (Circuitbox) to protect API calls.
- Supports batch upsert for performance and memory efficiency.
- Sync jobs run both on-demand and scheduled with Sidekiq-Cron.
- API exposes filtered issue list with pagination headers.

## Setup

1. **Install dependencies**

    `bundle install`

2. **Configure Redis and Sidekiq**

Ensure Redis is running and configured for background jobs.

3. **Run migrations**

    `rails db:migrate`

4. **Start Sidekiq**

     `bundle exec sidekiq`


5. **Run the Rails server**

    `rails server`

7. **Access Sidekiq Web UI**

Visit [http://localhost:3000/sidekiq](http://localhost:3000/sidekiq) to monitor background jobs.

## Usage

### API Docs

    http://localhost:3000/api-docs/

### API Endpoint

GET `/api/v1/issues`

- Optional query parameter: `state` (`open` or `closed`)
- Returns paginated JSON list of issues including user information.

Example request:


    curl "http://localhost:3000/api/v1/issues?state=open"


### Synchronization

- On-demand: Sync is triggered automatically when accessing the issues API if last sync was over 5 minutes ago.
- Scheduled: A Sidekiq-Cron job runs every 30 minutes to keep issues updated.

### Configuration

- Circuit breaker configured in `GithubIssueService` controls fault tolerance and timeouts.
- Batch sizes and sync intervals can be adjusted in service code.

## Testing

Run RSpec tests:

    bundle exec rspec

## Monitoring & Logging

- Logs errors and circuit breaker state changes.
- Supports Sidekiq Web UI with access for job monitoring.

---
