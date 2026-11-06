# Galones vendidos de un combustible y a cuánto se vendió cada galón
class Venta < ActiveRecord::Base
  # Sin esto, ActiveRecord busca la tabla "venta" en vez de "ventas"
  self.table_name = 'ventas'

  belongs_to :gasolinera
  validates :combustible, inclusion: { in: Gasolinera::COMBUSTIBLES }

  def total
    galones * precio
  end
end
