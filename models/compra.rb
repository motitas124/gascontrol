# Galones comprados de un combustible y a cuánto se compró cada galón
class Compra < ActiveRecord::Base
  belongs_to :gasolinera
  validates :combustible, inclusion: { in: Gasolinera::COMBUSTIBLES }

  def total
    galones * precio
  end
end
