# frozen_string_literal: true

class IssueSerializer < ActiveModel::Serializer
  attributes :number, :state, :title, :body, :created_at, :updated_at

  belongs_to :user, serializer: UserSerializer
end
