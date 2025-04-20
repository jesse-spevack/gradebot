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

ActiveRecord::Schema[8.0].define(version: 2025_04_13_155327) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "assignment_prompts", force: :cascade do |t|
    t.string "title", null: false
    t.integer "word_count"
    t.string "grade_level"
    t.string "subject"
    t.date "due_date"
    t.integer "grading_task_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "content"
    t.index ["grading_task_id"], name: "index_assignment_prompts_on_grading_task_id"
  end

  create_table "criteria", force: :cascade do |t|
    t.integer "rubric_id", null: false
    t.string "title", null: false
    t.text "description"
    t.integer "points", null: false
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["rubric_id", "position"], name: "index_criteria_on_rubric_id_and_position", unique: true
    t.index ["rubric_id"], name: "index_criteria_on_rubric_id"
  end

  create_table "document_actions", force: :cascade do |t|
    t.integer "student_submission_id", null: false
    t.integer "action_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.text "error_message"
    t.datetime "completed_at"
    t.datetime "failed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_document_actions_on_status"
    t.index ["student_submission_id", "action_type"], name: "idx_on_student_submission_id_action_type_fb34529644"
    t.index ["student_submission_id"], name: "index_document_actions_on_student_submission_id"
  end

  create_table "document_selections", force: :cascade do |t|
    t.integer "grading_task_id", null: false
    t.string "document_id", null: false
    t.string "name"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["grading_task_id"], name: "index_document_selections_on_grading_task_id"
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

  create_table "features", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "release_date"
  end

  create_table "grading_task_summaries", force: :cascade do |t|
    t.integer "grading_task_id", null: false
    t.integer "submissions_count", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.text "insights"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["grading_task_id"], name: "index_grading_task_summaries_on_grading_task_id"
  end

  create_table "grading_tasks", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0
    t.integer "lock_version", default: 0, null: false
    t.integer "rubric_id"
    t.string "feedback_tone"
    t.index ["rubric_id"], name: "index_grading_tasks_on_rubric_id"
    t.index ["user_id"], name: "index_grading_tasks_on_user_id"
  end

  create_table "levels", force: :cascade do |t|
    t.integer "criterion_id", null: false
    t.string "title", null: false
    t.text "description"
    t.integer "points", null: false
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["criterion_id", "position"], name: "index_levels_on_criterion_id_and_position", unique: true
    t.index ["criterion_id"], name: "index_levels_on_criterion_id"
  end

  create_table "llm_cost_logs", force: :cascade do |t|
    t.integer "user_id"
    t.string "trackable_type"
    t.integer "trackable_id"
    t.string "request_type"
    t.string "llm_model_name"
    t.integer "prompt_tokens"
    t.integer "completion_tokens"
    t.integer "total_tokens"
    t.decimal "cost", precision: 10, scale: 6
    t.string "request_id"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_llm_cost_logs_on_created_at"
    t.index ["llm_model_name"], name: "index_llm_cost_logs_on_llm_model_name"
    t.index ["request_id"], name: "index_llm_cost_logs_on_request_id"
    t.index ["request_type"], name: "index_llm_cost_logs_on_request_type"
    t.index ["trackable_type", "trackable_id"], name: "index_llm_cost_logs_on_trackable"
    t.index ["user_id"], name: "index_llm_cost_logs_on_user_id"
  end

  create_table "llm_pricing_configs", force: :cascade do |t|
    t.string "llm_model_name", null: false
    t.decimal "prompt_rate", precision: 10, scale: 6, default: "0.0", null: false
    t.decimal "completion_rate", precision: 10, scale: 6, default: "0.0", null: false
    t.text "description"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["llm_model_name"], name: "index_llm_pricing_configs_on_llm_model_name", unique: true
  end

  create_table "opportunities", force: :cascade do |t|
    t.string "recordable_type", null: false
    t.integer "recordable_id", null: false
    t.text "content", null: false
    t.text "reason", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recordable_type", "recordable_id"], name: "index_opportunities_on_recordable"
  end

  create_table "raw_rubrics", force: :cascade do |t|
    t.text "content", null: false
    t.integer "grading_task_id", null: false
    t.integer "rubric_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["grading_task_id"], name: "index_raw_rubrics_on_grading_task_id"
    t.index ["rubric_id"], name: "index_raw_rubrics_on_rubric_id"
  end

  create_table "rubric_criterion_scores", force: :cascade do |t|
    t.integer "student_submission_id", null: false
    t.integer "criterion_id", null: false
    t.integer "level_id", null: false
    t.integer "points_earned", null: false
    t.text "reason", null: false
    t.text "evidence", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["criterion_id"], name: "index_rubric_criterion_scores_on_criterion_id"
    t.index ["level_id"], name: "index_rubric_criterion_scores_on_level_id"
    t.index ["student_submission_id"], name: "index_rubric_criterion_scores_on_student_submission_id"
  end

  create_table "rubrics", force: :cascade do |t|
    t.string "title"
    t.integer "user_id"
    t.integer "total_points", default: 100
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_rubrics_on_user_id"
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

  create_table "strengths", force: :cascade do |t|
    t.string "recordable_type", null: false
    t.integer "recordable_id", null: false
    t.text "content", null: false
    t.text "reason", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recordable_type", "recordable_id"], name: "index_strengths_on_recordable"
  end

  create_table "student_submission_checks", force: :cascade do |t|
    t.integer "student_submission_id", null: false
    t.integer "check_type", null: false
    t.integer "score", null: false
    t.text "reason", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["student_submission_id"], name: "index_student_submission_checks_on_student_submission_id"
  end

  create_table "student_submissions", force: :cascade do |t|
    t.integer "grading_task_id", null: false
    t.integer "status", default: 0, null: false
    t.text "feedback"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "lock_version", default: 0, null: false
    t.string "overall_grade"
    t.integer "document_selection_id"
    t.index ["document_selection_id"], name: "index_student_submissions_on_document_selection_id"
    t.index ["grading_task_id", "status"], name: "index_submissions_on_grading_task_id_and_status"
    t.index ["grading_task_id"], name: "index_student_submissions_on_grading_task_id"
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

  add_foreign_key "document_selections", "grading_tasks"
  add_foreign_key "feature_flag_audit_logs", "feature_flags"
  add_foreign_key "feature_flag_audit_logs", "users"
  add_foreign_key "grading_task_summaries", "grading_tasks"
  add_foreign_key "grading_tasks", "rubrics"
  add_foreign_key "grading_tasks", "users"
  add_foreign_key "levels", "criteria"
  add_foreign_key "llm_cost_logs", "users"
  add_foreign_key "raw_rubrics", "grading_tasks"
  add_foreign_key "raw_rubrics", "rubrics"
  add_foreign_key "rubric_criterion_scores", "criteria"
  add_foreign_key "rubric_criterion_scores", "levels"
  add_foreign_key "rubric_criterion_scores", "student_submissions"
  add_foreign_key "rubrics", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "student_submission_checks", "student_submissions"
  add_foreign_key "student_submissions", "document_selections"
  add_foreign_key "student_submissions", "grading_tasks"
  add_foreign_key "user_tokens", "users"
end
