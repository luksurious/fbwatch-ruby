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

ActiveRecord::Schema.define(version: 20131008000246) do

  create_table "basicdata", force: true do |t|
    t.integer  "resource_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "key"
    t.text     "value"
  end

  create_table "feed_tags", force: true do |t|
    t.integer "feed_id"
    t.integer "resource_id"
  end

  create_table "feeds", force: true do |t|
    t.string   "facebook_id"
    t.text     "data"
    t.string   "data_type"
    t.string   "feed_type"
    t.datetime "created_time"
    t.datetime "updated_time"
    t.integer  "like_count"
    t.integer  "comment_count"
    t.integer  "resource_id"
    t.integer  "from_id"
    t.integer  "to_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id"
  end

  create_table "group_metrics", force: true do |t|
    t.string   "metric_class"
    t.string   "resources_token"
    t.string   "name"
    t.text     "value"
    t.integer  "resource_group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "group_metrics_resources", id: false, force: true do |t|
    t.integer "group_metric_id"
    t.integer "resource_id"
  end

  add_index "group_metrics_resources", ["group_metric_id"], name: "index_group_metrics_resources_on_group_metric_id", using: :btree
  add_index "group_metrics_resources", ["resource_id", "group_metric_id"], name: "index_group_metrics_resources_on_resource_and_group_metric", unique: true, using: :btree
  add_index "group_metrics_resources", ["resource_id"], name: "index_group_metrics_resources_on_resource_id", using: :btree

  create_table "likes", force: true do |t|
    t.integer  "resource_id"
    t.integer  "feed_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "metrics", force: true do |t|
    t.string   "metric_id"
    t.string   "name"
    t.string   "description"
    t.string   "value"
    t.integer  "resource_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "resource_groups", force: true do |t|
    t.string "group_name"
  end

  create_table "resource_groups_resources", id: false, force: true do |t|
    t.integer "resource_id"
    t.integer "resource_group_id"
  end

  add_index "resource_groups_resources", ["resource_group_id"], name: "index_resource_groups_resources_on_resource_group_id", using: :btree
  add_index "resource_groups_resources", ["resource_id", "resource_group_id"], name: "index_resource_groups_resources_on_resource_and_resource_group", unique: true, using: :btree
  add_index "resource_groups_resources", ["resource_id"], name: "index_resource_groups_resources_on_resource_id", using: :btree

  create_table "resources", force: true do |t|
    t.string   "name"
    t.string   "facebook_id"
    t.datetime "last_synced"
    t.boolean  "active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "username"
    t.string   "link"
  end

  add_index "resources", ["facebook_id"], name: "index_resources_on_facebook_id", using: :btree
  add_index "resources", ["username"], name: "index_resources_on_username", unique: true, using: :btree

  create_table "tasks", force: true do |t|
    t.integer  "resource_id"
    t.integer  "resource_group_id"
    t.string   "type"
    t.decimal  "progress",          precision: 2, scale: 1
    t.integer  "duration"
    t.text     "data"
    t.boolean  "running"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
