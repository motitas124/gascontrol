require 'sinatra/base'
require 'sinatra/activerecord'
require 'bigdecimal'

require_relative 'lib/css_builder'
require_relative 'helpers/format_helpers'
require_relative 'helpers/auth_helpers'

# Modelos (gasolinera primero: define la lista de combustibles)
require_relative 'models/gasolinera'
require_relative 'models/compra'
require_relative 'models/venta'
require_relative 'models/flete'
require_relative 'models/user'
require_relative 'models/evaluacion'

require_relative 'controllers/auth_controller'
require_relative 'controllers/gasolineras_controller'

class App < Sinatra::Base
  register Sinatra::ActiveRecordExtension
  set :database_file, File.join(__dir__, 'config', 'database.yml')

  # Archivos estáticos (public/css/app.css se genera con Sass)
  set :public_folder, File.join(__dir__, 'public')
  enable :static

  # En desarrollo, recompila el .scss al recargar la página
  configure(:development) { use SassRecarga }

  enable :sessions
  set :session_secret, ENV.fetch('SESSION_SECRET') {
    'clave-solo-para-desarrollo-cambiala-en-produccion-' + 'x' * 40
  }

  use AuthController
  use GasolinerasController

  get('/') { redirect '/gasolineras/nueva' }

  run! if app_file == $0
end
