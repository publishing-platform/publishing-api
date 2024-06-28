class CreatePathReservations < ActiveRecord::Migration[7.1]
  def change
    create_table :path_reservations do |t|
      t.text :base_path, null: false
      t.string :publishing_app, null: false

      t.timestamps

      t.index :base_path, unique: true        
    end
  end
end
