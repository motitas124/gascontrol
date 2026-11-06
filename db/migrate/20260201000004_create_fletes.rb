class CreateFletes < ActiveRecord::Migration[7.1]
  def change
    create_table :fletes do |t|
      t.references :gasolinera, null: false, foreign_key: true
      t.string :descripcion
      t.decimal :valor, precision: 12, scale: 2, null: false, default: 0
      t.timestamps
    end
  end
end
