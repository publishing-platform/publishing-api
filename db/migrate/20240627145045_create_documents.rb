class CreateDocuments < ActiveRecord::Migration[7.1]
  def change
    create_table :documents do |t|
      t.uuid :content_id, null: false
      t.integer :stale_lock_version, default: 0, null: false

      t.references :owning_document, foreign_key: { to_table: :documents, on_delete: :restrict }

      t.timestamps

      t.index :content_id, unique: true      
    end
  end
end
