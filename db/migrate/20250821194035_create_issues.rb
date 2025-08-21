# frozen_string_literal: true

class CreateIssues < ActiveRecord::Migration[7.1]
  def change
    create_table :issues do |t|
      t.bigint :github_id, null: false
      t.bigint :number, null: false
      t.string :state, null: false
      t.string :title, null: false
      t.text :body
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :issues, :github_id, unique: true
    add_index :issues, :number, unique: true
  end
end
