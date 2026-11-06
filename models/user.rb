class User < ActiveRecord::Base
  has_secure_password   # encripta la contraseña con bcrypt
  has_many :gasolineras, dependent: :destroy

  before_validation { self.email = email.to_s.strip.downcase }

  validates :email, presence: { message: 'El correo es obligatorio' },
                    format: { with: URI::MailTo::EMAIL_REGEXP, message: 'El correo no es válido' },
                    uniqueness: { message: 'Ese correo ya está registrado' }
  validates :password, length: { minimum: 6, message: 'La contraseña debe tener al menos 6 caracteres' },
                       if: -> { password.present? || new_record? }
end
