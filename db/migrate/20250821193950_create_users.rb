# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.bigint :github_id, null: false
      t.string :login, null: false
      t.string :avatar_url, null: false
      t.string :user_type, null: false
      t.string :url, null: false

      t.timestamps
    end

    add_index :users, :github_id, unique: true
  end
end
