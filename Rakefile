require 'sinatra/activerecord/rake'

namespace :db do
  task :load_config do
    require './app'
  end
end

# ---------- Datos de demostración ----------
namespace :demo do
  desc 'Carga un usuario y tres gasolineras de ejemplo (db/seeds.rb)'
  task cargar: 'db:load_config' do
    load File.join(__dir__, 'db', 'seeds.rb')
  end
end

# ---------- Sass ----------
namespace :css do
  desc 'Compila scss/main.scss a public/css/app.css'
  task :build do
    require_relative 'lib/css_builder'
    CssBuilder.compilar
    puts 'CSS compilado en public/css/app.css'
  end

  desc 'Vigila la carpeta scss/ y recompila al guardar'
  task :watch do
    require_relative 'lib/css_builder'
    puts 'Vigilando scss/ (Ctrl+C para salir)...'
    loop do
      if CssBuilder.desactualizado?
        begin
          CssBuilder.compilar
          puts "[#{Time.now.strftime('%H:%M:%S')}] CSS recompilado"
        rescue StandardError => e
          puts "Error de Sass: #{e.message}"
        end
      end
      sleep 1
    end
  end
end
