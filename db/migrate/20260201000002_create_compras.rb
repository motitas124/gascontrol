class CreateCompras < ActiveRecord::Migration[7.1]
  def change
    create_table :compras do |t|
      t.references :gasolinera, null: false, foreign_key: true
      t.string :combustible, null: false
      t.decimal :galones, precision: 12, scale: 2, null: false, default: 0
      t.decimal :precio,  precision: 12, scale: 4, null: false, default: 0
      t.timestamps
    end
  end
end
