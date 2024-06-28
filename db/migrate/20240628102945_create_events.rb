class CreateEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :events do |t|
      t.uuid :content_id
      t.string :action, null: false
      t.string :user_uid
      t.string :request_id      
      t.jsonb :payload, default: {}

      t.timestamps
    end
  end
end
