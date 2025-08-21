# frozen_string_literal: true

class Issue < ApplicationRecord
  belongs_to :user

  enum state: { open: "open", closed: "closed" }

  validates :github_id, presence: true, uniqueness: true
  validates :number, presence: true, numericality: { only_integer: true }
  validates :state, presence: true, inclusion: { in: states.keys }
  validates :title, presence: true
  validates :created_at, presence: true
  validates :updated_at, presence: true

  scope :by_state, ->(state) { where(state:) if state.present? }
end
