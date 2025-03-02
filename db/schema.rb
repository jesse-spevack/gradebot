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

ActiveRecord::Schema[8.0].define(version: 2025_03_02_145200) do
  create_table "email_signups", force: :cascade do |t|
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_email_signups_on_email", unique: true
  end

  create_table "feature_flag_audit_logs", force: :cascade do |t|
    t.integer "feature_flag_id", null: false
    t.integer "user_id", null: false
    t.string "action", null: false
    t.boolean "previous_state", null: false
    t.boolean "new_state", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_feature_flag_audit_logs_on_created_at"
    t.index ["feature_flag_id"], name: "index_feature_flag_audit_logs_on_feature_flag_id"
    t.index ["user_id"], name: "index_feature_flag_audit_logs_on_user_id"
  end

  create_table "feature_flags", force: :cascade do |t|
    t.string "key", null: false
    t.string "name", null: false
    t.text "description"
    t.boolean "enabled", default: false, null: false
    t.datetime "last_changed_at", default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_feature_flags_on_key", unique: true
  end

  create_table "grading_tasks", force: :cascade do |t|
    t.integer "user_id", null: false
    t.text "assignment_prompt"
    t.string "folder_id"
    t.string "folder_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "grading_rubric"
    t.integer "status", default: 0
    t.integer "lock_version", default: 0, null: false
    t.index ["user_id"], name: "index_grading_tasks_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent", null: false
    t.string "ip_address", null: false
    t.string "access_token"
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "student_submissions", force: :cascade do |t|
    t.integer "grading_task_id", null: false
    t.string "original_doc_id", null: false
    t.integer "status", default: 0, null: false
    t.text "feedback"
    t.string "graded_doc_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "lock_version", default: 0, null: false
    t.index ["grading_task_id", "status"], name: "index_submissions_on_grading_task_id_and_status"
    t.index ["grading_task_id"], name: "index_student_submissions_on_grading_task_id"
    t.index ["original_doc_id"], name: "index_student_submissions_on_original_doc_id"
    t.index ["status"], name: "index_student_submissions_on_status"
  end

  create_table "user_tokens", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "access_token"
    t.string "refresh_token"
    t.datetime "expires_at"
    t.text "scopes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_tokens_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "name", null: false
    t.string "google_uid", null: false
    t.string "profile_picture_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["google_uid"], name: "index_users_on_google_uid", unique: true
  end

  add_foreign_key "feature_flag_audit_logs", "feature_flags"
  add_foreign_key "feature_flag_audit_logs", "users"
  add_foreign_key "grading_tasks", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "student_submissions", "grading_tasks"
  add_foreign_key "user_tokens", "users"
end
