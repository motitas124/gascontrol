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

ActiveRecord::Schema[8.1].define(version: 2026_02_01_000004) do
  create_table "compras", force: :cascade do |t|
    t.integer "gasolinera_id", null: false
    t.string "combustible", null: false
    t.decimal "galones", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "precio", precision: 12, scale: 4, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gasolinera_id"], name: "index_compras_on_gasolinera_id"
  end

  create_table "fletes", force: :cascade do |t|
    t.integer "gasolinera_id", null: false
    t.string "descripcion"
    t.decimal "valor", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gasolinera_id"], name: "index_fletes_on_gasolinera_id"
  end

  create_table "gasolineras", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "nombre", null: false
    t.string "ubicacion", null: false
    t.text "problemas"
    t.text "riesgos"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_gasolineras_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "ventas", force: :cascade do |t|
    t.integer "gasolinera_id", null: false
    t.string "combustible", null: false
    t.decimal "galones", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "precio", precision: 12, scale: 4, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gasolinera_id"], name: "index_ventas_on_gasolinera_id"
  end

  add_foreign_key "compras", "gasolineras"
  add_foreign_key "fletes", "gasolineras"
  add_foreign_key "gasolineras", "users"
  add_foreign_key "ventas", "gasolineras"
end
