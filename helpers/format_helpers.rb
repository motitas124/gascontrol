# Funciones para mostrar dinero, galones y porcentajes
module FormatHelpers
  def miles(entero)
    entero.to_s.reverse.scan(/\d{1,3}/).join(',').reverse
  end

  def money(valor)
    v = valor.to_f
    ent, dec = format('%.2f', v.abs).split('.')
    "#{v < 0 ? '-' : ''}$#{miles(ent)}.#{dec}"
  end

  def gal(valor)
    v = valor.to_f
    a = v.abs
    texto = (a - a.round).abs < 0.005 ? a.round.to_s : format('%.2f', a)
    ent, dec = texto.split('.')
    "#{v < 0 ? '-' : ''}#{miles(ent)}#{dec ? '.' + dec : ''} gal"
  end

  def pct(valor)
    "#{format('%.1f', valor.to_f)}%"
  end

  # Número que cambia cuando se recompila el CSS (evita que el navegador use uno viejo)
  def css_version
    File.mtime(File.expand_path('../public/css/app.css', __dir__)).to_i
  rescue Errno::ENOENT
    0
  end

  # Número listo para mostrarlo dentro de un campo de formulario
  def num_input(valor)
    return '' if valor.nil?
    texto = valor.is_a?(BigDecimal) ? valor.to_s('F') : valor.to_s
    texto.sub(/\.0+\z/, '')
  end
end
