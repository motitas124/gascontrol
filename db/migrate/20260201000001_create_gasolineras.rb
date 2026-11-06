class CreateGasolineras < ActiveRecord::Migration[7.1]
  def change
    create_table :gasolineras do |t|
      t.references :user, null: false, foreign_key: true
      t.string :nombre, null: false
      t.string :ubicacion, null: false
      t.text :problemas
      t.text :riesgos
      t.timestamps
    end
  end
end
