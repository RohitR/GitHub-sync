# frozen_string_literal: true

FactoryBot.define do
  factory :issue do
    association :user

    sequence(:github_id) { |n| n + 1000 }
    sequence(:number) { |n| n + 100 }  # ensure unique number

    state { "open" }
    title { "Test Issue" }
    created_at { Time.current }
    updated_at { Time.current }
    github_updated_at { Time.current }
  end
end
