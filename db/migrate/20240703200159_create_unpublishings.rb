class CreateUnpublishings < ActiveRecord::Migration[7.1]
  def change
    create_table :unpublishings do |t|    
      t.string :type, null: false
      t.text :explanation
      t.text :alternative_path
      t.datetime :unpublished_at, precision: nil
      t.jsonb :redirects

      t.references :edition, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }

      t.timestamps 

      t.index [:edition_id, :type], name: "index_unpublishings_on_edition_id_and_type"
    end
  end
end
