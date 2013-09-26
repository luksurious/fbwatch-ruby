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

ActiveRecord::Schema.define(version: 20130924182126) do

  create_table "DATABASECHANGELOG", id: false, force: true do |t|
    t.string   "ID",            limit: 63,  null: false
    t.string   "AUTHOR",        limit: 63,  null: false
    t.string   "FILENAME",      limit: 200, null: false
    t.datetime "DATEEXECUTED",              null: false
    t.integer  "ORDEREXECUTED",             null: false
    t.string   "EXECTYPE",      limit: 10,  null: false
    t.string   "MD5SUM",        limit: 35
    t.string   "DESCRIPTION"
    t.string   "COMMENTS"
    t.string   "TAG"
    t.string   "LIQUIBASE",     limit: 20
  end

  create_table "DATABASECHANGELOGLOCK", primary_key: "ID", force: true do |t|
    t.boolean  "LOCKED",      null: false
    t.datetime "LOCKGRANTED"
    t.string   "LOCKEDBY"
  end

  create_table "algoridesingle", force: true do |t|
    t.datetime "createdon",              null: false
    t.datetime "lastmodified"
    t.integer  "ridesingle",   limit: 8
  end

  add_index "algoridesingle", ["ridesingle"], name: "FKB1BC81D39D810FEA", using: :btree

  create_table "algosearchsingle", force: true do |t|
    t.datetime "createdon",              null: false
    t.datetime "lastmodified"
    t.integer  "searchsingle", limit: 8
  end

  add_index "algosearchsingle", ["searchsingle"], name: "FKE90BE1C36FD856CA", using: :btree

  create_table "basicdata", force: true do |t|
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "key"
    t.text     "value"
    t.integer  "resource_id", null: false
  end

  create_table "car", force: true do |t|
    t.datetime "createdon",                 null: false
    t.datetime "lastmodified"
    t.string   "carplate"
    t.string   "color"
    t.string   "comment",      limit: 1600
    t.binary   "defaultcar",   limit: 1,    null: false
    t.binary   "deleted",      limit: 1,    null: false
    t.string   "model"
    t.integer  "places",                    null: false
    t.binary   "smoker",       limit: 1,    null: false
    t.integer  "owner",        limit: 8,    null: false
  end

  add_index "car", ["owner"], name: "FK17FD4D4D4E455", using: :btree

  create_table "company", force: true do |t|
    t.datetime "createdon",    null: false
    t.datetime "lastmodified"
    t.string   "name",         null: false
    t.string   "prefix",       null: false
  end

  create_table "favoritelocation", force: true do |t|
    t.datetime "createdon",                null: false
    t.datetime "lastmodified"
    t.integer  "company",      limit: 8,   null: false
    t.binary   "location",     limit: 255
  end

  add_index "favoritelocation", ["company"], name: "FK93CC0D5119CF38B8", using: :btree

  create_table "feedevent", force: true do |t|
    t.string   "type",     limit: 31, null: false
    t.datetime "date",                null: false
    t.integer  "status",              null: false
    t.integer  "value",    limit: 8,  null: false
    t.integer  "feeditem", limit: 8,  null: false
  end

  add_index "feedevent", ["feeditem"], name: "FK9E5B5FBCD2698F4B", using: :btree

  create_table "feeditem", force: true do |t|
    t.datetime "createdon",               null: false
    t.datetime "lastmodified"
    t.datetime "lasteventdate"
    t.integer  "ridesingle",    limit: 8
    t.integer  "searchsingle",  limit: 8
    t.integer  "user",          limit: 8, null: false
  end

  add_index "feeditem", ["ridesingle"], name: "FKF49961B19D810FEA", using: :btree
  add_index "feeditem", ["searchsingle"], name: "FKF49961B16FD856CA", using: :btree
  add_index "feeditem", ["user"], name: "FKF49961B1CEB7DD6D", using: :btree

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
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
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
  add_index "group_metrics_resources", ["resource_id", "group_metric_id"], name: "index_group_metrics_resources_on_resource_id_and_group_metric_id", unique: true, using: :btree
  add_index "group_metrics_resources", ["resource_id"], name: "index_group_metrics_resources_on_resource_id", using: :btree

  create_table "hibernate_sequences", id: false, force: true do |t|
    t.string  "sequence_name"
    t.integer "sequence_next_hi_value"
  end

  create_table "likes", force: true do |t|
    t.integer  "resource_id"
    t.integer  "feed_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "location", force: true do |t|
    t.datetime "createdon",    null: false
    t.datetime "lastmodified"
    t.string   "cityname"
    t.string   "country"
    t.string   "displayname",  null: false
    t.float    "latitude",     null: false
    t.float    "longitude",    null: false
    t.string   "postalcode"
    t.string   "streetname"
    t.string   "streetnumber"
  end

  create_table "loginlog", force: true do |t|
    t.string   "useragent"
    t.integer  "user",         limit: 8, null: false
    t.datetime "createdon",              null: false
    t.datetime "lastmodified"
  end

  add_index "loginlog", ["user"], name: "FK78910F3BCEB7DD6D", using: :btree

  create_table "metrics", force: true do |t|
    t.string   "metric_id"
    t.string   "name"
    t.string   "description"
    t.string   "value"
    t.integer  "resource_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mobilenumbertracker", force: true do |t|
    t.datetime "createdon",                             null: false
    t.datetime "lastmodified"
    t.string   "matchstateatrequestingpoint",           null: false
    t.string   "feedbackcomment"
    t.string   "result"
    t.integer  "passenger",                   limit: 8, null: false
    t.integer  "user",                        limit: 8, null: false
  end

  add_index "mobilenumbertracker", ["passenger"], name: "FKA35A6E6D5454AA76", using: :btree
  add_index "mobilenumbertracker", ["user"], name: "FKA35A6E6DCEB7DD6D", using: :btree

  create_table "offerrepetition", force: true do |t|
    t.datetime "createdon",                 null: false
    t.datetime "lastmodified"
    t.datetime "endday"
    t.binary   "onfriday",        limit: 1
    t.binary   "onmonday",        limit: 1
    t.binary   "onsaturday",      limit: 1
    t.binary   "onsunday",        limit: 1
    t.binary   "onthursday",      limit: 1
    t.binary   "ontuesday",       limit: 1
    t.binary   "onwednesday",     limit: 1
    t.binary   "repetitiveoffer", limit: 1, null: false
    t.datetime "startday"
  end

  create_table "passenger", force: true do |t|
    t.datetime "createdon",                                            null: false
    t.datetime "lastmodified"
    t.datetime "arrivalhelper",                                        null: false
    t.datetime "departuredate",                                        null: false
    t.datetime "departurehelper",                                      null: false
    t.integer  "distances_approachdistance_distinmeter",               null: false
    t.integer  "distances_approachdistance_distinsec",                 null: false
    t.integer  "distances_detourdistance_distinmeter",                 null: false
    t.integer  "distances_detourdistance_distinsec",                   null: false
    t.integer  "distances_originalridedistance_distinmeter",           null: false
    t.integer  "distances_originalridedistance_distinsec",             null: false
    t.string   "matchstatedriver",                                     null: false
    t.string   "matchstatepassenger",                                  null: false
    t.integer  "numberofpassengers",                                   null: false
    t.float    "pricedriver",                                          null: false
    t.float    "pricepassenger",                                       null: false
    t.integer  "timewindowinmsec",                           limit: 8, null: false
    t.integer  "dropoff",                                    limit: 8, null: false
    t.integer  "pickup",                                     limit: 8, null: false
    t.integer  "ridesingle",                                 limit: 8, null: false
    t.integer  "rideuser",                                   limit: 8, null: false
    t.integer  "search",                                     limit: 8, null: false
    t.integer  "searchuser",                                 limit: 8, null: false
    t.integer  "distances_passengerdistance_distinmeter",              null: false
    t.integer  "distances_passengerdistance_distinsec",                null: false
  end

  add_index "passenger", ["dropoff"], name: "FKC7AF549AE271AB8A", using: :btree
  add_index "passenger", ["pickup"], name: "FKC7AF549A34BE51E6", using: :btree
  add_index "passenger", ["ridesingle"], name: "FKC7AF549A9D810FEA", using: :btree
  add_index "passenger", ["rideuser"], name: "FKC7AF549A73A00A65", using: :btree
  add_index "passenger", ["search"], name: "FKC7AF549AFCA8B082", using: :btree
  add_index "passenger", ["searchuser"], name: "FKC7AF549AA4372F15", using: :btree

  create_table "rating", force: true do |t|
    t.datetime "createdon",              null: false
    t.datetime "lastmodified"
    t.string   "comment"
    t.datetime "date",                   null: false
    t.integer  "givenrating",            null: false
    t.integer  "receiver",     limit: 8, null: false
    t.integer  "ridesingle",   limit: 8, null: false
    t.integer  "sender",       limit: 8, null: false
  end

  add_index "rating", ["receiver"], name: "FKC815B19D9E4CDB91", using: :btree
  add_index "rating", ["ridesingle"], name: "FKC815B19D9D810FEA", using: :btree
  add_index "rating", ["sender"], name: "FKC815B19D98810BD7", using: :btree

  create_table "registrationcode", force: true do |t|
    t.datetime "createdon",                  null: false
    t.datetime "lastmodified"
    t.string   "code",                       null: false
    t.string   "marketingelement"
    t.integer  "company",          limit: 8, null: false
  end

  add_index "registrationcode", ["code"], name: "code", unique: true, using: :btree
  add_index "registrationcode", ["company"], name: "FK5AD922619CF38B8", using: :btree

  create_table "repetitiveoffercreatedondate", force: true do |t|
    t.datetime "createdon",      null: false
    t.datetime "lastmodified"
    t.datetime "date",           null: false
    t.string   "ridesearchtype", null: false
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
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "username"
    t.string   "link"
  end

  add_index "resources", ["facebook_id"], name: "facebook_id", using: :btree
  add_index "resources", ["facebook_id"], name: "index_resources_on_facebook_id", using: :btree
  add_index "resources", ["username"], name: "index_resources_on_username", unique: true, using: :btree

  create_table "ridecomment", force: true do |t|
    t.datetime "createdon",                 null: false
    t.datetime "lastmodified"
    t.string   "comment",      limit: 1600, null: false
    t.datetime "date",                      null: false
    t.integer  "type"
    t.integer  "passenger",    limit: 8
    t.integer  "ridegroup",    limit: 8
    t.integer  "ridesingle",   limit: 8
    t.integer  "search",       limit: 8
    t.integer  "searchgroup",  limit: 8
    t.integer  "sender",       limit: 8,    null: false
  end

  add_index "ridecomment", ["passenger"], name: "FK9F2EFE67886B5AAA", using: :btree
  add_index "ridecomment", ["ridegroup"], name: "FK9F2EFE67F3469264", using: :btree
  add_index "ridecomment", ["ridesingle"], name: "FK9F2EFE679D810FEA", using: :btree
  add_index "ridecomment", ["search"], name: "FK9F2EFE67FCA8B082", using: :btree
  add_index "ridecomment", ["searchgroup"], name: "FK9F2EFE67A77AEF84", using: :btree
  add_index "ridecomment", ["sender"], name: "FK9F2EFE6798810BD7", using: :btree

  create_table "ridegroup", force: true do |t|
    t.datetime "createdon",                                      null: false
    t.datetime "lastmodified"
    t.string   "arrivaldeparture",                               null: false
    t.datetime "date",                                           null: false
    t.integer  "durationwithoutpassenger_distinmeter",           null: false
    t.integer  "durationwithoutpassenger_distinsec",             null: false
    t.binary   "onlycompany",                          limit: 1, null: false
    t.binary   "onlywomen",                            limit: 1, null: false
    t.integer  "timewindowinmsec",                     limit: 8, null: false
    t.integer  "locationdestination",                  limit: 8, null: false
    t.integer  "locationstart",                        limit: 8, null: false
    t.integer  "owner",                                limit: 8, null: false
    t.integer  "repetition",                           limit: 8, null: false
    t.integer  "maxsecondsdetour",                               null: false
    t.integer  "paymentmethod_donationid"
    t.integer  "paymentmethod_type"
    t.float    "priceentiredistance",                            null: false
    t.float    "pricefactor",                                    null: false
    t.integer  "numberoffreeplaces",                             null: false
    t.integer  "car",                                  limit: 8, null: false
    t.integer  "comment",                              limit: 8
    t.binary   "visible",                              limit: 1, null: false
  end

  add_index "ridegroup", ["car"], name: "FKFE698C64720562F1fdfe6887", using: :btree
  add_index "ridegroup", ["comment"], name: "FKFDFE688723B3B09C", using: :btree
  add_index "ridegroup", ["locationdestination"], name: "FK64C1A5CD81078A3fe698c64fdfe6887", using: :btree
  add_index "ridegroup", ["locationstart"], name: "FK64C1A5C5ACF537fe698c64fdfe6887", using: :btree
  add_index "ridegroup", ["owner"], name: "FK64C1A5CD4D4E455fe698c64fdfe6887", using: :btree
  add_index "ridegroup", ["repetition"], name: "FK64C1A5C25938D54fe698c64fdfe6887", using: :btree

  create_table "ridesingle", force: true do |t|
    t.datetime "createdon",                                      null: false
    t.datetime "lastmodified"
    t.string   "arrivaldeparture",                               null: false
    t.datetime "date",                                           null: false
    t.integer  "durationwithoutpassenger_distinmeter",           null: false
    t.integer  "durationwithoutpassenger_distinsec",             null: false
    t.binary   "onlycompany",                          limit: 1, null: false
    t.binary   "onlywomen",                            limit: 1, null: false
    t.integer  "timewindowinmsec",                     limit: 8, null: false
    t.integer  "locationdestination",                  limit: 8, null: false
    t.integer  "locationstart",                        limit: 8, null: false
    t.integer  "owner",                                limit: 8, null: false
    t.integer  "repetition",                           limit: 8, null: false
    t.integer  "maxsecondsdetour",                               null: false
    t.integer  "paymentmethod_donationid"
    t.integer  "paymentmethod_type"
    t.float    "priceentiredistance",                            null: false
    t.float    "pricefactor",                                    null: false
    t.integer  "numberoffreeplaces",                             null: false
    t.integer  "car",                                  limit: 8, null: false
    t.integer  "currentdetour_distinmeter",                      null: false
    t.integer  "currentdetour_distinsec",                        null: false
    t.integer  "freeplaces",                                     null: false
    t.binary   "inalgo",                               limit: 1, null: false
    t.binary   "visible",                              limit: 1, null: false
    t.integer  "ridegroup",                            limit: 8
  end

  add_index "ridesingle", ["car"], name: "FKFE698C64720562F1d5c95340", using: :btree
  add_index "ridesingle", ["locationdestination"], name: "FK64C1A5CD81078A3fe698c64d5c95340", using: :btree
  add_index "ridesingle", ["locationstart"], name: "FK64C1A5C5ACF537fe698c64d5c95340", using: :btree
  add_index "ridesingle", ["owner"], name: "FK64C1A5CD4D4E455fe698c64d5c95340", using: :btree
  add_index "ridesingle", ["repetition"], name: "FK64C1A5C25938D54fe698c64d5c95340", using: :btree
  add_index "ridesingle", ["ridegroup"], name: "FKD5C95340F3469264", using: :btree

  create_table "roles", primary_key: "roleid", force: true do |t|
    t.string "rolename", null: false
  end

  create_table "route", force: true do |t|
    t.datetime "createdon",                   null: false
    t.datetime "lastmodified"
    t.integer  "arrivallocation",   limit: 8, null: false
    t.integer  "departurelocation", limit: 8, null: false
    t.integer  "owner",             limit: 8, null: false
  end

  add_index "route", ["arrivallocation"], name: "FK67AB2491EFCECC", using: :btree
  add_index "route", ["departurelocation"], name: "FK67AB249B1B6C8C7", using: :btree
  add_index "route", ["owner"], name: "FK67AB249D4D4E455", using: :btree

  create_table "searchgroup", force: true do |t|
    t.datetime "createdon",                                      null: false
    t.datetime "lastmodified"
    t.string   "arrivaldeparture",                               null: false
    t.datetime "date",                                           null: false
    t.integer  "durationwithoutpassenger_distinmeter",           null: false
    t.integer  "durationwithoutpassenger_distinsec",             null: false
    t.binary   "onlycompany",                          limit: 1, null: false
    t.binary   "onlywomen",                            limit: 1, null: false
    t.integer  "timewindowinmsec",                     limit: 8, null: false
    t.integer  "locationdestination",                  limit: 8, null: false
    t.integer  "locationstart",                        limit: 8, null: false
    t.integer  "owner",                                limit: 8, null: false
    t.integer  "repetition",                           limit: 8, null: false
    t.integer  "numberofpassengers",                             null: false
    t.binary   "visible",                              limit: 1, null: false
    t.integer  "comment",                              limit: 8
  end

  add_index "searchgroup", ["comment"], name: "FK4C084B0423B3B09Ce04bd9d7", using: :btree
  add_index "searchgroup", ["locationdestination"], name: "FK64C1A5CD81078A34c084b04e04bd9d7", using: :btree
  add_index "searchgroup", ["locationstart"], name: "FK64C1A5C5ACF5374c084b04e04bd9d7", using: :btree
  add_index "searchgroup", ["owner"], name: "FK64C1A5CD4D4E4554c084b04e04bd9d7", using: :btree
  add_index "searchgroup", ["repetition"], name: "FK64C1A5C25938D544c084b04e04bd9d7", using: :btree

  create_table "searchsingle", force: true do |t|
    t.datetime "createdon",                                      null: false
    t.datetime "lastmodified"
    t.string   "arrivaldeparture",                               null: false
    t.datetime "date",                                           null: false
    t.integer  "durationwithoutpassenger_distinmeter",           null: false
    t.integer  "durationwithoutpassenger_distinsec",             null: false
    t.binary   "onlycompany",                          limit: 1, null: false
    t.binary   "onlywomen",                            limit: 1, null: false
    t.integer  "timewindowinmsec",                     limit: 8, null: false
    t.integer  "locationdestination",                  limit: 8, null: false
    t.integer  "locationstart",                        limit: 8, null: false
    t.integer  "owner",                                limit: 8, null: false
    t.integer  "repetition",                           limit: 8, null: false
    t.binary   "inalgo",                               limit: 1, null: false
    t.integer  "numberofpassengers",                             null: false
    t.binary   "visible",                              limit: 1, null: false
    t.integer  "comment",                              limit: 8
    t.integer  "searchgroup",                          limit: 8
    t.binary   "createdbyuser",                        limit: 1
  end

  add_index "searchsingle", ["comment"], name: "FK4C084B0423B3B09C3d2a0bf0", using: :btree
  add_index "searchsingle", ["locationdestination"], name: "FK64C1A5CD81078A34c084b043d2a0bf0", using: :btree
  add_index "searchsingle", ["locationstart"], name: "FK64C1A5C5ACF5374c084b043d2a0bf0", using: :btree
  add_index "searchsingle", ["owner"], name: "FK64C1A5CD4D4E4554c084b043d2a0bf0", using: :btree
  add_index "searchsingle", ["repetition"], name: "FK64C1A5C25938D544c084b043d2a0bf0", using: :btree
  add_index "searchsingle", ["searchgroup"], name: "FK3D2A0BF0A77AEF84", using: :btree

  create_table "timedlocation", force: true do |t|
    t.datetime "createdon",              null: false
    t.datetime "lastmodified"
    t.datetime "date"
    t.integer  "userlocation", limit: 8
  end

  add_index "timedlocation", ["userlocation"], name: "FK5DA07FECAF58D7EA", using: :btree

  create_table "timedroutelocation", force: true do |t|
    t.datetime "createdon",                    null: false
    t.datetime "lastmodified"
    t.datetime "date"
    t.integer  "userlocation",       limit: 8
    t.integer  "distfromstartinsec"
    t.string   "type"
    t.integer  "passenger",          limit: 8
    t.integer  "ridesingle",         limit: 8, null: false
    t.integer  "user",               limit: 8, null: false
  end

  add_index "timedroutelocation", ["passenger"], name: "FK1B91A327886B5AAA", using: :btree
  add_index "timedroutelocation", ["ridesingle"], name: "FK1B91A3279D810FEA", using: :btree
  add_index "timedroutelocation", ["user"], name: "FK1B91A327CEB7DD6D", using: :btree
  add_index "timedroutelocation", ["userlocation"], name: "FK5DA07FECAF58D7EA1b91a327", using: :btree

  create_table "tosaccepted", force: true do |t|
    t.datetime "createdon",                  null: false
    t.datetime "lastmodified"
    t.integer  "acceptedrevision"
    t.integer  "user",             limit: 8, null: false
  end

  add_index "tosaccepted", ["user"], name: "FK39FE98EFCEB7DD6D", using: :btree

  create_table "user", force: true do |t|
    t.datetime "createdon",                                           null: false
    t.datetime "lastmodified"
    t.string   "accesskey",                                           null: false
    t.string   "androidtoken"
    t.string   "comment",                                limit: 1600
    t.float    "creditbalance",                                       null: false
    t.string   "displayname",                                         null: false
    t.string   "email",                                               null: false
    t.binary   "emailnotification",                      limit: 1,    null: false
    t.string   "firstname",                                           null: false
    t.string   "gender"
    t.string   "iphonetoken"
    t.string   "lastname",                                            null: false
    t.string   "mobilephone",                                         null: false
    t.binary   "phonenumbervalidated",                   limit: 1,    null: false
    t.string   "phonenumbervalidationcode",                           null: false
    t.integer  "phonenumbervalidationsmssent",                        null: false
    t.integer  "privacyoptions_facebookinfos"
    t.binary   "privacyoptions_likerideonfacebook",      limit: 1
    t.integer  "privacyoptions_phonenumber"
    t.integer  "privacyoptions_profilephoto"
    t.binary   "privacyoptions_showmypositiontopartner", limit: 1
    t.binary   "privacyoptions_showrideonstartscreen",   limit: 1
    t.string   "pwd",                                                 null: false
    t.string   "secret",                                              null: false
    t.integer  "company",                                limit: 8,    null: false
    t.integer  "registrationcode",                       limit: 8,    null: false
  end

  add_index "user", ["accesskey"], name: "accesskey", unique: true, using: :btree
  add_index "user", ["company"], name: "FK36EBCB19CF38B8", using: :btree
  add_index "user", ["mobilephone"], name: "mobilephone", unique: true, using: :btree
  add_index "user", ["registrationcode"], name: "FK36EBCBCB4AE6E", using: :btree

  create_table "userlocation", force: true do |t|
    t.datetime "createdon",              null: false
    t.datetime "lastmodified"
    t.string   "cityname"
    t.string   "country"
    t.string   "displayname",            null: false
    t.float    "latitude",               null: false
    t.float    "longitude",              null: false
    t.string   "postalcode"
    t.string   "streetname"
    t.string   "streetnumber"
    t.integer  "callcount",              null: false
    t.binary   "favorite",     limit: 1, null: false
    t.integer  "owner",        limit: 8
  end

  add_index "userlocation", ["owner"], name: "FK3FAF9080D4D4E455", using: :btree

  create_table "userroles", force: true do |t|
    t.datetime "createdon",              null: false
    t.datetime "lastmodified"
    t.integer  "role",                   null: false
    t.integer  "user",         limit: 8, null: false
  end

  add_index "userroles", ["role"], name: "FK154649D21A6C43C", using: :btree
  add_index "userroles", ["user"], name: "FK154649D2CEB7DD6D", using: :btree

end
