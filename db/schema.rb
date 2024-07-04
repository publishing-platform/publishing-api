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

ActiveRecord::Schema[7.1].define(version: 2024_07_03_200159) do
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
    t.index ["edition_id"], name: "index_change_notes_on_edition_id", unique: true
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

  create_table "expanded_links", force: :cascade do |t|
    t.uuid "content_id", null: false
    t.boolean "with_drafts", null: false
    t.bigint "payload_version", default: 0, null: false
    t.jsonb "expanded_links", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_id", "with_drafts"], name: "expanded_links_content_id_with_drafts_index", unique: true
  end

  create_table "link_changes", force: :cascade do |t|
    t.uuid "source_content_id", null: false
    t.uuid "target_content_id", null: false
    t.string "link_type", null: false
    t.integer "change", null: false
    t.bigint "action_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action_id"], name: "index_link_changes_on_action_id"
    t.index ["created_at"], name: "index_link_changes_on_created_at", order: :desc
  end

  create_table "link_sets", force: :cascade do |t|
    t.uuid "content_id"
    t.integer "stale_lock_version", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_id"], name: "index_link_sets_on_content_id", unique: true
  end

  create_table "links", force: :cascade do |t|
    t.uuid "target_content_id"
    t.string "link_type", null: false
    t.integer "position", default: 0, null: false
    t.bigint "edition_id"
    t.bigint "link_set_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["edition_id"], name: "index_links_on_edition_id"
    t.index ["link_set_id", "target_content_id"], name: "index_links_on_link_set_id_and_target_content_id"
    t.index ["link_set_id"], name: "index_links_on_link_set_id"
    t.index ["link_type"], name: "index_links_on_link_type"
    t.index ["target_content_id", "link_type"], name: "index_links_on_target_content_id_and_link_type"
    t.index ["target_content_id"], name: "index_links_on_target_content_id"
  end

  create_table "path_reservations", force: :cascade do |t|
    t.text "base_path", null: false
    t.string "publishing_app", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["base_path"], name: "index_path_reservations_on_base_path", unique: true
  end

  create_table "unpublishings", force: :cascade do |t|
    t.string "type", null: false
    t.text "explanation"
    t.text "alternative_path"
    t.datetime "unpublished_at", precision: nil
    t.jsonb "redirects"
    t.bigint "edition_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["edition_id", "type"], name: "index_unpublishings_on_edition_id_and_type"
    t.index ["edition_id"], name: "index_unpublishings_on_edition_id", unique: true
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
  add_foreign_key "link_changes", "actions", on_delete: :cascade
  add_foreign_key "links", "editions", on_delete: :cascade
  add_foreign_key "links", "link_sets", on_delete: :restrict
  add_foreign_key "unpublishings", "editions", on_delete: :cascade
end
