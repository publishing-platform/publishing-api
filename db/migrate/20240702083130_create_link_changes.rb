class CreateLinkChanges < ActiveRecord::Migration[7.1]
  def change
    create_table :link_changes do |t|     
      t.uuid :source_content_id, null: false
      t.uuid :target_content_id, null: false
      t.string :link_type, null: false
      t.integer :change, null: false

      t.references :action, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps  

      t.index [:created_at], name: "index_link_changes_on_created_at", order: :desc
    end
  end
end
