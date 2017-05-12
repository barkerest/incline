# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20170511230126) do

  create_table "incline_users", force: :cascade do |t|
    t.string   "name",              limit: 100,                 null: false
    t.string   "email",             limit: 250,                 null: false
    t.boolean  "activated",                     default: false, null: false
    t.boolean  "enabled",                       default: true,  null: false
    t.boolean  "system_admin",                  default: false, null: false
    t.string   "activation_digest", limit: 100
    t.string   "password_digest",   limit: 100
    t.string   "remember_digest",   limit: 100
    t.string   "reset_digest",      limit: 100
    t.datetime "activated_at"
    t.datetime "reset_sent_at"
    t.string   "disabled_by",       limit: 250
    t.datetime "disabled_at"
    t.string   "disabled_reason",   limit: 200
    t.datetime "last_login_at"
    t.string   "last_login_ip",     limit: 64
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
  end

  add_index "incline_users", ["email"], name: "ux_incline_users_email", unique: true

end
