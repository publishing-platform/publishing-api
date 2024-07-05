class CreateLinkSets < ActiveRecord::Migration[7.1]
  def change
    create_table :link_sets do |t|
      t.uuid :content_id
      t.integer :stale_lock_version, default: 0

      t.timestamps

      t.index :content_id, name: "index_link_sets_on_content_id", unique: true
    end
  end
end
