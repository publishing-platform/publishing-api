class CreateChangeNotes < ActiveRecord::Migration[7.1]
  def change
    create_table :change_notes do |t|
      t.text :note, default: ""
      t.datetime :public_timestamp, precision: nil

      t.references :edition, null: false, foreign_key: { on_delete: :restrict }, index: { unique: true }

      t.timestamps
    end
  end
end
