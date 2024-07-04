class CreateEditions < ActiveRecord::Migration[7.1]
  def change
    create_table :editions do |t|
      t.text :title      
      t.text :description
      t.text :base_path
      t.string :state, null: false  
      t.integer :user_facing_version, default: 1, null: false
      t.datetime :public_updated_at, precision: nil
      t.string :update_type
      t.string :phase, default: "live"
      t.string :content_store
      t.string :publishing_app
      t.string :rendering_app      
      t.string :document_type
      t.string :schema_name      
      t.datetime :first_published_at, precision: nil
      t.datetime :published_at, precision: nil        
      t.datetime :last_edited_at, precision: nil  
      t.string :publishing_request_id
      t.datetime :major_published_at, precision: nil
      t.string :auth_bypass_ids, default: [], null: false, array: true  
      t.jsonb :details, default: {}                
      t.jsonb :routes, default: []
      t.jsonb :redirects, default: []

      t.references :document, null: false, foreign_key: { on_delete: :restrict }

      t.timestamps
  
      t.index [:base_path, :content_store], name: "index_editions_on_base_path_and_content_store", unique: true
      t.index [:document_id, :content_store], name: "index_editions_on_document_id_and_content_store", unique: true
      t.index [:document_id, :state], name: "index_editions_on_document_id_and_state"
      t.index [:document_id, :user_facing_version], name: "index_editions_on_document_id_and_user_facing_version", unique: true
      t.index [:document_type, :state], name: "index_editions_on_document_type_and_state"
      t.index [:document_type, :updated_at], name: "index_editions_on_document_type_and_updated_at"
      t.index [:id, :content_store], name: "index_editions_on_id_and_content_store"
      t.index [:publishing_app], name: "index_editions_on_publishing_app"
      t.index [:state, :base_path], name: "index_editions_on_state_and_base_path"
      t.index [:updated_at, :id], name: "index_editions_on_updated_at_and_id"
      t.index [:updated_at], name: "index_editions_on_updated_at"      
    end
  end
end
