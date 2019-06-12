# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_05_04_002926) do

  create_table "_blank", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_czech_ci", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "audits", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_czech_ci", force: :cascade do |t|
    t.integer "auditable_id"
    t.string "auditable_type"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.text "audited_changes"
    t.integer "version", default: 0
    t.string "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at"
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "cas", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_czech_ci", force: :cascade do |t|
    t.string "name"
    t.boolean "internal"
    t.string "path"
    t.text "key"
    t.text "certificate"
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "apache_config"
  end

  create_table "certificates", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_czech_ci", force: :cascade do |t|
    t.bigint "ca_id"
    t.string "name"
    t.text "certificate"
    t.text "key"
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ca_id"], name: "index_certificates_on_ca_id"
  end

  create_table "redirects", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_czech_ci", force: :cascade do |t|
    t.string "name"
    t.string "backend"
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ca_id"
    t.text "apache_config"
    t.boolean "apache_saved", default: false, null: false
  end

  create_table "tyb_cas", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_czech_ci", force: :cascade do |t|
    t.string "name"
    t.string "path"
    t.text "key"
    t.text "certificate"
    t.text "data"
    t.text "apache_config"
    t.datetime "last_check"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "modul"
  end

  create_table "tyb_certificates", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_czech_ci", force: :cascade do |t|
    t.bigint "ca_id"
    t.string "name"
    t.text "certificate"
    t.text "key"
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "generated"
    t.boolean "autoupdate", default: false
    t.datetime "date_time_end_at"
    t.datetime "last_update_at"
    t.string "domain"
    t.integer "days", default: 365
    t.string "token"
    t.integer "status", default: 0
    t.string "gen_key_type"
    t.string "gen_key_size"
    t.datetime "token_expired_at"
    t.string "order_url"
    t.text "ca_certificate"
    t.index ["ca_id"], name: "index_tyb_certificates_on_ca_id"
  end

  create_table "tyb_configurations", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_czech_ci", force: :cascade do |t|
    t.string "group"
    t.string "name"
    t.text "value"
    t.string "value_type"
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tyb_logs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_czech_ci", force: :cascade do |t|
    t.integer "status"
    t.string "title"
    t.text "content"
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tyb_redirects", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_czech_ci", force: :cascade do |t|
    t.string "name"
    t.string "host"
    t.string "backend"
    t.bigint "certificate_id"
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "apache_config"
    t.boolean "auto_write_apache"
    t.boolean "apache_written"
    t.boolean "internal"
    t.string "cert_path"
    t.index ["certificate_id"], name: "index_tyb_redirects_on_certificate_id"
  end

  add_foreign_key "certificates", "cas"
  add_foreign_key "tyb_certificates", "cas"
end
