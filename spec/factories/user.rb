# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    github_id { Faker::Number.unique.number(digits: 6) }
    login { Faker::Internet.username }
    avatar_url { Faker::Internet.url }
    user_type { "User" }
    url { Faker::Internet.url }
  end
end
