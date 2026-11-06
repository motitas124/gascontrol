require 'fileutils'

# Compila scss/main.scss a public/css/app.css con Sass (gema sass-embedded).
#
#   bundle exec rake css:build    compila una vez
#   bundle exec rake css:watch    recompila cada vez que guardas un .scss
#
# En desarrollo (ruby app.rb) también se recompila solo al recargar la página.
module CssBuilder
  CARPETA = File.expand_path('../scss', __dir__)
  ORIGEN  = File.join(CARPETA, 'main.scss')
  DESTINO = File.expand_path('../public/css/app.css', __dir__)

  def self.compilar(estilo: :expanded)
    require 'sass-embedded'
    resultado = Sass.compile(ORIGEN, style: estilo)
    FileUtils.mkdir_p(File.dirname(DESTINO))
    File.write(DESTINO, "/* Generado desde scss/main.scss con Sass. No lo edites a mano. */\n#{resultado.css}\n")
    true
  end

  # true si algún .scss es más nuevo que el CSS generado
  def self.desactualizado?
    return true unless File.exist?(DESTINO)
    ultimo = Dir.glob(File.join(CARPETA, '**', '*.scss')).map { |f| File.mtime(f) }.max
    !ultimo.nil? && ultimo > File.mtime(DESTINO)
  end
end

# Middleware solo para desarrollo: antes de atender cada petición,
# recompila el CSS si cambió algún .scss. Si Sass no está instalado
# o el .scss tiene un error, avisa en la terminal y usa el CSS anterior.
class SassRecarga
  def initialize(app)
    @app = app
  end

  def call(env)
    if CssBuilder.desactualizado?
      begin
        CssBuilder.compilar
        puts '[Sass] CSS recompilado: public/css/app.css'
      rescue LoadError
        warn '[Sass] Falta la gema sass-embedded. Ejecuta: bundle install'
      rescue StandardError => e
        warn "[Sass] Error al compilar: #{e.message}"
      end
    end
    @app.call(env)
  end
end
