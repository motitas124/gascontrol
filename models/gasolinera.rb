class Gasolinera < ActiveRecord::Base
  # Combustibles fijos. Para agregar otro, solo añádelo a esta lista.
  COMBUSTIBLES = ['Super', 'Diesel', 'Ecopaís'].freeze

  belongs_to :user
  has_many :compras, dependent: :destroy
  has_many :ventas,  dependent: :destroy
  has_many :fletes,  dependent: :destroy

  validates :nombre,    presence: { message: 'El nombre de la gasolinera es obligatorio' }
  validates :ubicacion, presence: { message: 'La ubicación de la gasolinera es obligatoria' }
end
