class CreateActions < ActiveRecord::Migration[7.1]
  def change
    create_table :actions do |t|     
      t.uuid :content_id, null: false
      t.string :action, null: false
      t.uuid :user_uid
      t.integer :edition_id
      t.integer :link_set_id
      t.integer :event_id, null: false
      
      t.timestamps       
    end
  end
end
