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

ActiveRecord::Schema.define(:version => 20130622111526) do

  create_table "basicdata", :force => true do |t|
    t.string   "name"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "link"
    t.string   "username"
    t.integer  "hometown_id"
    t.string   "hometown"
    t.integer  "location_id"
    t.string   "location"
    t.string   "gender"
    t.string   "email"
    t.integer  "timezone"
    t.string   "locale"
    t.boolean  "verified"
    t.datetime "updated_time"
    t.integer  "resource_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "resources", :force => true do |t|
    t.string   "name"
    t.string   "facebook_id"
    t.datetime "last_synced"
    t.boolean  "active"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "resources", ["name"], :name => "index_resources_on_name", :unique => true

end
