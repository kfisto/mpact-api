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

ActiveRecord::Schema.define(version: 20151112003344) do

  create_table "entries", force: true do |t|
    t.string  "guideKey"
    t.string  "name"
    t.string  "image"
    t.binary  "data",      limit: 8192
    t.integer "entrytype"
    t.string  "location"
    t.text    "bio",       limit: 2048
    t.boolean "include",                default: true
  end

  create_table "guides", force: true do |t|
    t.string "key"
    t.string "image"
    t.string "title"
    t.string "textLabel"
  end

  create_table "notes", force: true do |t|
    t.text     "text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "entry_id"
    t.string   "author"
  end

  create_table "ops", force: true do |t|
    t.text    "description", limit: 2048
    t.integer "category"
    t.string  "what"
    t.string  "when"
    t.string  "where"
  end

  create_table "requests", force: true do |t|
    t.text    "request",  limit: 2048
    t.integer "entry_id"
  end

end
