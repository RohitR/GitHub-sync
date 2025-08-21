# frozen_string_literal: true

class User < ApplicationRecord
  has_many :issues, dependent: :nullify

  validates :github_id, presence: true, uniqueness: true
  validates :login, presence: true
  validates :avatar_url, presence: true
  validates :user_type, presence: true
  validates :url, presence: true
end
