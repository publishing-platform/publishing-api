class CreateExpandedLinks < ActiveRecord::Migration[7.1]
  def change
    create_table :expanded_links do |t|
      t.uuid :content_id, null: false
      t.boolean :with_drafts, null: false
      t.bigint :payload_version, default: 0, null: false
      t.jsonb :expanded_links, default: {}, null: false

      t.timestamps

      t.index %i[content_id with_drafts], name: "expanded_links_content_id_with_drafts_index", unique: true
    end
  end
end
