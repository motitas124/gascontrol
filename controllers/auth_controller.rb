class AuthController < Sinatra::Base
  # Código único que se pide para crear un usuario
  CODIGO_REGISTRO = ENV.fetch('CODIGO_REGISTRO', '252516')

  set :views, File.expand_path('../views', __dir__)
  helpers AuthHelpers, FormatHelpers

  # Registro (requiere el código único)
  get '/register' do
    redirect '/gasolineras/nueva' if logged_in?
    @user = User.new
    erb :register
  end

  post '/register' do
    @user = User.new(email: params[:email], password: params[:password],
                     password_confirmation: params[:password_confirmation])

    unless Rack::Utils.secure_compare(params[:codigo].to_s.strip, CODIGO_REGISTRO)
      @error_codigo = 'El código único es incorrecto.'
      return erb(:register)
    end

    if @user.save
      session.clear
      session[:user_id] = @user.id
      redirect '/gasolineras/nueva'
    else
      erb :register
    end
  end

  # Inicio de sesión
  get '/login' do
    redirect '/gasolineras/nueva' if logged_in?
    erb :login
  end

  post '/login' do
    user = User.find_by(email: params[:email].to_s.strip.downcase)

    if user && user.authenticate(params[:password])
      session.clear
      session[:user_id] = user.id
      redirect '/gasolineras/nueva'
    else
      @error = 'Correo o contraseña incorrectos'
      erb :login
    end
  end

  # Cierre de sesión
  post '/logout' do
    session.clear
    redirect '/login'
  end
end
