class CreateLinks < ActiveRecord::Migration[7.1]
  def change
    create_table :links do |t|     
      t.uuid :target_content_id
      t.string :link_type, null: false
      t.integer :position, default: 0, null: false

      t.references :edition, foreign_key: { on_delete: :cascade }
      t.references :link_set, foreign_key: { on_delete: :restrict }

      t.timestamps       

      t.index [:link_set_id, :target_content_id], name: "index_links_on_link_set_id_and_target_content_id"    
      t.index [:link_type], name: "index_links_on_link_type"
      t.index [:target_content_id, :link_type], name: "index_links_on_target_content_id_and_link_type"
      t.index [:target_content_id], name: "index_links_on_target_content_id"
    end
  end
end
