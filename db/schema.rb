# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 202407011112122) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "actions", force: :cascade do |t|
    t.uuid "content_id", null: false
    t.string "action", null: false
    t.uuid "user_uid"
    t.integer "edition_id"
    t.integer "link_set_id"
    t.integer "event_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "change_notes", force: :cascade do |t|
    t.text "note", default: ""
    t.datetime "public_timestamp", precision: nil
    t.bigint "edition_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["edition_id"], name: "index_change_notes_on_edition_id"
  end

  create_table "documents", force: :cascade do |t|
    t.uuid "content_id", null: false
    t.integer "stale_lock_version", default: 0, null: false
    t.bigint "owning_document_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_id"], name: "index_documents_on_content_id", unique: true
    t.index ["owning_document_id"], name: "index_documents_on_owning_document_id"
  end

  create_table "editions", force: :cascade do |t|
    t.text "title"
    t.text "description"
    t.text "base_path"
    t.string "state", null: false
    t.integer "user_facing_version", default: 1, null: false
    t.datetime "public_updated_at", precision: nil
    t.string "update_type"
    t.string "phase", default: "live"
    t.string "content_store"
    t.string "publishing_app"
    t.string "rendering_app"
    t.string "document_type"
    t.string "schema_name"
    t.datetime "first_published_at", precision: nil
    t.datetime "published_at", precision: nil
    t.datetime "last_edited_at", precision: nil
    t.string "publishing_request_id"
    t.datetime "major_published_at", precision: nil
    t.string "auth_bypass_ids", default: [], null: false, array: true
    t.jsonb "details", default: {}
    t.jsonb "routes", default: []
    t.jsonb "redirects", default: []
    t.bigint "document_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["base_path", "content_store"], name: "index_editions_on_base_path_and_content_store", unique: true
    t.index ["document_id", "content_store"], name: "index_editions_on_document_id_and_content_store", unique: true
    t.index ["document_id", "state"], name: "index_editions_on_document_id_and_state"
    t.index ["document_id", "user_facing_version"], name: "index_editions_on_document_id_and_user_facing_version", unique: true
    t.index ["document_id"], name: "index_editions_on_document_id"
    t.index ["document_type", "state"], name: "index_editions_on_document_type_and_state"
    t.index ["document_type", "updated_at"], name: "index_editions_on_document_type_and_updated_at"
    t.index ["id", "content_store"], name: "index_editions_on_id_and_content_store"
    t.index ["publishing_app"], name: "index_editions_on_publishing_app"
    t.index ["state", "base_path"], name: "index_editions_on_state_and_base_path"
    t.index ["updated_at", "id"], name: "index_editions_on_updated_at_and_id"
    t.index ["updated_at"], name: "index_editions_on_updated_at"
  end

  create_table "events", force: :cascade do |t|
    t.uuid "content_id"
    t.string "action", null: false
    t.string "user_uid"
    t.string "request_id"
    t.jsonb "payload", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "path_reservations", force: :cascade do |t|
    t.text "base_path", null: false
    t.string "publishing_app", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["base_path"], name: "index_path_reservations_on_base_path", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "uid"
    t.string "organisation_slug"
    t.string "organisation_content_id"
    t.string "app_name"
    t.text "permissions"
    t.boolean "disabled", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "change_notes", "editions", on_delete: :restrict
  add_foreign_key "documents", "documents", column: "owning_document_id", on_delete: :restrict
  add_foreign_key "editions", "documents", on_delete: :restrict
end
