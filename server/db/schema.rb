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

ActiveRecord::Schema[8.1].define(version: 2026_09_19_203550) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "audio_uploads", force: :cascade do |t|
    t.integer "bitrate", null: false
    t.datetime "created_at", null: false
    t.float "duration", null: false
    t.string "file_hash", null: false
    t.string "filename", null: false
    t.boolean "is_outlier", default: false, null: false
    t.integer "quality_score", null: false
    t.integer "sample_rate", null: false
    t.string "storage_path", null: false
    t.datetime "updated_at", null: false
    t.index ["file_hash"], name: "index_audio_uploads_on_file_hash", unique: true
    t.check_constraint "duration > 5::double precision", name: "chk_duration_greater_than_five"
    t.check_constraint "quality_score >= 1 AND quality_score <= 10", name: "chk_quality_score_range"
  end
end
