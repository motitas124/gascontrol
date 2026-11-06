class GasolinerasController < Sinatra::Base
  set :views, File.expand_path('../views', __dir__)
  set :method_override, true

  helpers AuthHelpers, FormatHelpers

  # Todo lo de las gasolineras exige haber iniciado sesión
  before do
    require_login if request.path_info =~ %r{\A/(gasolineras|comparativa|nueva-evaluacion)}
  end

  error ActiveRecord::RecordNotFound do
    status 404
    'Gasolinera no encontrada'
  end

  helpers do
    # Gasolineras registradas en la evaluación actual (para compararlas)
    def ronda
      session[:ronda] ||= []
    end

    def cargar_gasolinera
      @gasolinera = current_user.gasolineras.find(params[:id])
    end

    # Convierte el texto de un campo en número (nil si no es válido)
    def dec(valor)
      texto = valor.to_s.strip.tr(',', '.')
      return BigDecimal('0') if texto.empty?
      n = BigDecimal(texto)
      return nil unless n.finite?
      return nil if n > BigDecimal('1000000000')
      n
    rescue ArgumentError
      nil
    end

    # Lee los campos galones[0..n] y precio[0..n] del formulario
    def leer_filas
      errores = []
      filas = Gasolinera::COMBUSTIBLES.each_with_index.map do |c, i|
        g  = dec(params.dig('galones', i.to_s))
        pr = dec(params.dig('precio', i.to_s))
        if g.nil? || pr.nil? || g.negative? || pr.negative?
          errores << "#{c}: revisa los números; deben ser valores de 0 en adelante."
        elsif g > 0 && pr.zero?
          errores << "#{c}: escribe el precio por galón."
        end
        { combustible: c, galones: g, precio: pr }
      end
      [filas, errores]
    end

    def filas_desde(registros)
      lista = registros.to_a
      Gasolinera::COMBUSTIBLES.map do |c|
        r = lista.find { |x| x.combustible == c }
        { combustible: c, galones: num_input(r&.galones), precio: num_input(r&.precio) }
      end
    end

    def filas_desde_params
      Gasolinera::COMBUSTIBLES.each_with_index.map do |c, i|
        { combustible: c,
          galones: params.dig('galones', i.to_s).to_s,
          precio: params.dig('precio', i.to_s).to_s }
      end
    end
  end

  # ---------- Pestaña 1: registrar gasolinera ----------
  get '/gasolineras/nueva' do
    @gasolinera = Gasolinera.new
    erb :nueva
  end

  post '/gasolineras' do
    @gasolinera = current_user.gasolineras.build(nombre: params[:nombre].to_s.strip,
                                                 ubicacion: params[:ubicacion].to_s.strip)
    if @gasolinera.save
      session[:ronda] = ronda + [@gasolinera.id]
      redirect "/gasolineras/#{@gasolinera.id}/compras"
    else
      erb :nueva
    end
  end

  get '/gasolineras/:id/editar' do
    cargar_gasolinera
    erb :nueva
  end

  put '/gasolineras/:id' do
    cargar_gasolinera
    if @gasolinera.update(nombre: params[:nombre].to_s.strip, ubicacion: params[:ubicacion].to_s.strip)
      redirect "/gasolineras/#{@gasolinera.id}/compras"
    else
      erb :nueva
    end
  end

  # ---------- Pestaña 2: galones comprados ----------
  get '/gasolineras/:id/compras' do
    cargar_gasolinera
    @filas = filas_desde(@gasolinera.compras)
    erb :compras
  end

  post '/gasolineras/:id/compras' do
    cargar_gasolinera
    filas, errores = leer_filas
    if errores.empty? && filas.all? { |f| f[:galones].zero? }
      errores << 'Registra los galones de al menos un combustible.'
    end

    if errores.empty?
      Compra.transaction do
        @gasolinera.compras.destroy_all
        filas.each { |f| @gasolinera.compras.create!(f) }
      end
      redirect "/gasolineras/#{@gasolinera.id}/trailers"
    else
      @errores = errores
      @filas = filas_desde_params
      erb :compras
    end
  end

  # ---------- Trailers ----------
  get '/gasolineras/:id/trailers' do
    cargar_gasolinera
    @filas = @gasolinera.fletes.order(:id).map { |f| { descripcion: f.descripcion.to_s, valor: num_input(f.valor) } }
    erb :trailers
  end

  post '/gasolineras/:id/trailers' do
    cargar_gasolinera
    descripciones = Array(params[:descripcion])
    valores       = Array(params[:valor])
    nuevos  = []
    errores = []

    valores.each_with_index do |v, i|
      d = descripciones[i].to_s.strip
      next if v.to_s.strip.empty? && d.empty?
      n = dec(v)
      if n.nil? || n.negative?
        errores << "El valor del flete del trailer #{i + 1} no es válido."
      else
        nuevos << { descripcion: d, valor: n }
      end
    end

    if errores.empty?
      Flete.transaction do
        @gasolinera.fletes.destroy_all
        nuevos.each { |f| @gasolinera.fletes.create!(f) }
      end
      redirect "/gasolineras/#{@gasolinera.id}/ventas"
    else
      @errores = errores
      @filas = valores.each_with_index.map { |v, i| { descripcion: descripciones[i].to_s, valor: v.to_s } }
      erb :trailers
    end
  end

  # ---------- Pestaña 4: galones vendidos ----------
  get '/gasolineras/:id/ventas' do
    cargar_gasolinera
    @filas = filas_desde(@gasolinera.ventas)
    @listo = params[:listo] == '1' && @gasolinera.ventas.exists?
    @ev = Evaluacion.new(@gasolinera) if @listo
    erb :ventas
  end

  post '/gasolineras/:id/ventas' do
    cargar_gasolinera
    filas, errores = leer_filas
    compras = @gasolinera.compras.to_a

    filas.each do |f|
      next if f[:galones].nil?
      comprado = compras.find { |c| c.combustible == f[:combustible] }&.galones || BigDecimal('0')
      if f[:galones] > comprado
        errores << "#{f[:combustible]}: no puedes vender #{gal(f[:galones])} si solo compraste #{gal(comprado)}."
      end
    end

    if errores.empty?
      Venta.transaction do
        @gasolinera.ventas.destroy_all
        filas.each { |f| @gasolinera.ventas.create!(f) }
      end
      redirect "/gasolineras/#{@gasolinera.id}/ventas?listo=1"
    else
      @errores = errores
      @filas = filas_desde_params
      @listo = false
      erb :ventas
    end
  end

  # ---------- Pestaña 5: riesgos ----------
  get '/gasolineras/:id/riesgos' do
    cargar_gasolinera
    erb :riesgos
  end

  post '/gasolineras/:id/riesgos' do
    cargar_gasolinera
    @gasolinera.update(problemas: params[:problemas].to_s.strip, riesgos: params[:riesgos].to_s.strip)

    if params[:accion] == 'agregar'
      redirect '/gasolineras/nueva'
    elsif (ronda & current_user.gasolineras.pluck(:id)).size >= 2
      redirect '/comparativa'
    else
      redirect "/gasolineras/#{@gasolinera.id}/resultado"
    end
  end

  # ---------- Resultado de una gasolinera ----------
  get '/gasolineras/:id/resultado' do
    cargar_gasolinera
    @ev = Evaluacion.new(@gasolinera)
    @faltan = []
    @faltan << ['galones comprados', 'compras'] unless @gasolinera.compras.exists?
    @faltan << ['galones vendidos', 'ventas'] unless @gasolinera.ventas.exists?
    erb :resultado
  end

  # ---------- Comparativa de varias gasolineras ----------
  get '/comparativa' do
    ids = ronda
    gasolineras = current_user.gasolineras.where(id: ids).to_a.sort_by { |g| ids.index(g.id) }
    redirect '/gasolineras/nueva' if gasolineras.empty?
    redirect "/gasolineras/#{gasolineras.first.id}/resultado" if gasolineras.size == 1

    @evs = gasolineras.map { |g| Evaluacion.new(g) }
    candidatas = @evs.reject { |e| e.nivel == :rojo }
    @ganadora = candidatas.max_by { |e| [e.nivel == :verde ? 1 : 0, e.margen] }
    erb :comparativa
  end

  post '/nueva-evaluacion' do
    session[:ronda] = []
    redirect '/gasolineras/nueva'
  end
end
