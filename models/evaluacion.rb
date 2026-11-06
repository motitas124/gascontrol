# Calcula si una gasolinera es rentable usando los datos de todas las pestañas.
#
# Utilidad neta = ingresos por ventas - costo del combustible vendido - fletes
# Margen neto   = utilidad / ingresos * 100
# Rotación      = galones vendidos / galones comprados * 100
#
# Semáforo:
#   ROJO     utilidad <= 0, o margen menor a MARGEN_MINIMO, o no hay ventas
#   VERDE    margen >= MARGEN_BUENO y rotación >= ROTACION_BUENA
#            y riesgos reportados <= MAX_RIESGOS_VERDE
#   AMARILLO todo lo demás
class Evaluacion
  include FormatHelpers

  # Umbrales: cámbialos aquí si tu profesor pide otros criterios
  MARGEN_MINIMO     = BigDecimal('3')    # % de margen neto por debajo del cual es rojo
  MARGEN_BUENO      = BigDecimal('8')    # % de margen neto para ser verde
  ROTACION_BUENA    = BigDecimal('70')   # % de lo comprado que debe venderse para ser verde
  ROTACION_BAJA     = BigDecimal('50')   # % bajo el cual la rotación se considera mala
  FLETE_ALTO        = BigDecimal('10')   # % de los ingresos que se considera un flete alto
  MAX_RIESGOS_VERDE = 3                  # máximo de riesgos reportados para ser verde

  CERO = BigDecimal('0')
  CIEN = BigDecimal('100')

  attr_reader :gasolinera, :ingresos, :costo_vendido, :fletes, :utilidad, :margen,
              :rotacion, :fletes_pct, :n_riesgos, :nivel, :inventario,
              :galones_comprados, :galones_vendidos, :galones_restantes, :total_comprado

  def initialize(gasolinera)
    @gasolinera = gasolinera
    compras = gasolinera.compras.to_a
    ventas  = gasolinera.ventas.to_a

    @total_comprado    = suma(compras) { |c| c.galones * c.precio }
    @galones_comprados = suma(compras) { |c| c.galones }
    @galones_vendidos  = suma(ventas)  { |v| v.galones }
    @galones_restantes = @galones_comprados - @galones_vendidos
    @ingresos          = suma(ventas)  { |v| v.galones * v.precio }
    @costo_vendido     = suma(ventas) do |v|
      compra = compras.find { |c| c.combustible == v.combustible }
      compra ? v.galones * compra.precio : CERO
    end
    @fletes   = suma(gasolinera.fletes.to_a) { |f| f.valor }
    @utilidad = @ingresos - @costo_vendido - @fletes
    @margen   = @ingresos > CERO ? (@utilidad / @ingresos) * CIEN : CERO
    @rotacion = @galones_comprados > CERO ? (@galones_vendidos / @galones_comprados) * CIEN : CERO
    @fletes_pct =
      if @ingresos > CERO
        (@fletes / @ingresos) * CIEN
      else
        @fletes > CERO ? CIEN : CERO
      end
    @n_riesgos = items_de_riesgo.size

    @inventario = Gasolinera::COMBUSTIBLES.map do |c|
      comp = compras.select { |x| x.combustible == c }.sum(CERO) { |x| x.galones }
      vend = ventas.select  { |x| x.combustible == c }.sum(CERO) { |x| x.galones }
      { combustible: c, comprados: comp, vendidos: vend, restantes: comp - vend }
    end

    @nivel = clasificar
  end

  def etiqueta
    { rojo: 'No rentable', amarillo: 'Medianamente rentable', verde: 'Completamente rentable' }[@nivel]
  end

  def titulo_detalle
    { rojo: '¿Por qué no es rentable?', amarillo: 'Recomendaciones', verde: '¿Por qué es rentable?' }[@nivel]
  end

  def intro
    case @nivel
    when :rojo
      'Con los datos registrados, la gasolinera no es rentable.'
    when :amarillo
      "La gasolinera gana dinero (utilidad #{money(@utilidad)}, margen #{pct(@margen)}), pero no cumple todo lo necesario para ser completamente rentable."
    else
      'Con los datos registrados, la gasolinera es completamente rentable.'
    end
  end

  def detalle
    case @nivel
    when :rojo     then razones_rojo
    when :amarillo then recomendaciones
    else razones_verde
    end
  end

  # Decisión sugerida en la comparativa (el amarillo no tiene una definida)
  def accion
    { rojo: 'Vender', verde: 'Conservar' }[@nivel]
  end

  private

  def suma(lista, &bloque)
    lista.sum(CERO, &bloque)
  end

  def items_de_riesgo
    [gasolinera.problemas, gasolinera.riesgos].join("\n").split(/\n+/).map(&:strip).reject(&:empty?)
  end

  def clasificar
    if @ingresos <= CERO || @utilidad <= CERO || @margen < MARGEN_MINIMO
      :rojo
    elsif @margen >= MARGEN_BUENO && @rotacion >= ROTACION_BUENA && @n_riesgos <= MAX_RIESGOS_VERDE
      :verde
    else
      :amarillo
    end
  end

  def razones_rojo
    r = []
    if @ingresos <= CERO
      r << 'No hay ventas registradas, así que la gasolinera no ha generado ingresos.'
    elsif @utilidad <= CERO
      r << "Pierde dinero: los ingresos de #{money(@ingresos)} menos el costo del combustible vendido (#{money(@costo_vendido)}) y los fletes (#{money(@fletes)}) dan #{money(@utilidad)}."
    else
      r << "El margen neto es #{pct(@margen)}, por debajo del mínimo de #{pct(MARGEN_MINIMO)}."
    end
    if @galones_comprados > CERO && @rotacion < ROTACION_BAJA
      r << "Solo se vendió el #{pct(@rotacion)} del combustible comprado; #{gal(@galones_restantes)} siguen en inventario."
    end
    if @fletes > CERO && @fletes_pct >= FLETE_ALTO
      r << "Los fletes representan el #{pct(@fletes_pct)} de los ingresos."
    end
    if @n_riesgos > 0
      r << "Problemas o riesgos reportados: #{@n_riesgos}, que pueden afectar la venta de combustible."
    end
    r
  end

  def razones_verde
    [
      "Gana #{money(@utilidad)} con un margen neto de #{pct(@margen)} (el mínimo para ser completamente rentable es #{pct(MARGEN_BUENO)}).",
      "Vendió el #{pct(@rotacion)} del combustible comprado, así que el inventario rota bien.",
      "Los fletes son solo el #{pct(@fletes_pct)} de los ingresos.",
      "Los problemas o riesgos reportados son pocos (#{@n_riesgos}), por lo que amenazan poco las ventas."
    ]
  end

  def recomendaciones
    r = []
    if @margen < MARGEN_BUENO
      r << "Mejorar el margen: hoy es #{pct(@margen)} y conviene llegar al menos a #{pct(MARGEN_BUENO)}. Revisa el precio de venta o negocia un mejor precio de compra."
    end
    if @rotacion < ROTACION_BUENA
      r << "Vender más: se vendió el #{pct(@rotacion)} de lo comprado y conviene superar el #{pct(ROTACION_BUENA)}. Mientras tanto, compra menos galones para no dejar dinero parado (#{gal(@galones_restantes)} en inventario)."
    end
    if @fletes > CERO && @fletes_pct >= FLETE_ALTO
      r << "Reducir el costo de los fletes: representan el #{pct(@fletes_pct)} de los ingresos. Agrupa pedidos o compara transportistas."
    end
    if @n_riesgos > MAX_RIESGOS_VERDE
      r << "Controlar los riesgos: se reportaron #{@n_riesgos} problemas o riesgos. Atiende primero los que más afectan la venta de combustible."
    end
    r
  end
end
