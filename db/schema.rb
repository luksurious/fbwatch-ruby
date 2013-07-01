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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130630194423) do

  create_table "basicdata", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "key"
    t.string   "value"
  end

  create_table "feeds", :force => true do |t|
    t.string   "facebook_id"
    t.text     "data"
    t.string   "data_type"
    t.string   "feed_type"
    t.datetime "created_time"
    t.datetime "updated_time"
    t.integer  "likes"
    t.integer  "comments"
    t.integer  "resource_id"
    t.integer  "from_id"
    t.integer  "to_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.integer  "parent_id"
  end

  create_table "resources", :force => true do |t|
    t.string   "name"
    t.string   "facebook_id"
    t.datetime "last_synced"
    t.boolean  "active"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.string   "username"
    t.string   "link"
  end

  add_index "resources", ["username"], :name => "index_resources_on_username", :unique => true

end
