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

ActiveRecord::Schema.define(version: 20170622230422) do

  create_table "incline_access_group_group_members", force: :cascade do |t|
    t.integer  "group_id",   null: false
    t.integer  "member_id",  null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "incline_access_group_group_members", ["group_id", "member_id"], name: "ux_incline_access_group_group_members", unique: true
  add_index "incline_access_group_group_members", ["group_id"], name: "index_incline_access_group_group_members_on_group_id"
  add_index "incline_access_group_group_members", ["member_id"], name: "index_incline_access_group_group_members_on_member_id"

  create_table "incline_access_group_user_members", force: :cascade do |t|
    t.integer  "group_id",   null: false
    t.integer  "member_id",  null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "incline_access_group_user_members", ["group_id", "member_id"], name: "ux_incline_access_group_user_members", unique: true
  add_index "incline_access_group_user_members", ["group_id"], name: "index_incline_access_group_user_members_on_group_id"
  add_index "incline_access_group_user_members", ["member_id"], name: "index_incline_access_group_user_members_on_member_id"

  create_table "incline_access_groups", force: :cascade do |t|
    t.string   "name",       limit: 100, null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "incline_access_groups", ["name"], name: "ux_incline_access_groups_name", unique: true

  create_table "incline_action_groups", force: :cascade do |t|
    t.integer  "action_security_id", null: false
    t.integer  "access_group_id",    null: false
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  add_index "incline_action_groups", ["access_group_id"], name: "index_incline_action_groups_on_access_group_id"
  add_index "incline_action_groups", ["action_security_id", "access_group_id"], name: "ux_incline_action_groups", unique: true
  add_index "incline_action_groups", ["action_security_id"], name: "index_incline_action_groups_on_action_security_id"

  create_table "incline_action_securities", force: :cascade do |t|
    t.string   "controller_name",    limit: 200, null: false
    t.string   "action_name",        limit: 200, null: false
    t.text     "path",                           null: false
    t.boolean  "allow_anon"
    t.boolean  "require_anon"
    t.boolean  "require_admin"
    t.boolean  "unknown_controller"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.boolean  "non_standard"
    t.boolean  "visible"
  end

  add_index "incline_action_securities", ["controller_name", "action_name"], name: "ux_incline_action_securities", unique: true

  create_table "incline_user_login_histories", force: :cascade do |t|
    t.integer  "user_id",                null: false
    t.string   "ip_address", limit: 64,  null: false
    t.boolean  "successful"
    t.string   "message",    limit: 200
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "incline_user_login_histories", ["user_id"], name: "index_incline_user_login_histories_on_user_id"

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
    t.text     "comments"
  end

  add_index "incline_users", ["email"], name: "ux_incline_users_email", unique: true

end
