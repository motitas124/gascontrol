# =====================================================================
# Datos de demostración: un usuario y tres gasolineras (verde, amarillo
# y rojo) para probar el semáforo y la comparativa sin escribir nada.
#
#   bundle exec rake demo:cargar
#
# Se puede ejecutar varias veces: no duplica los datos.
# =====================================================================

DEMO_USUARIO = { email: 'demo@gascontrol.com', password: 'demo1234' }.freeze

# Para cada combustible: [galones, precio por galón]
DEMO_GASOLINERAS = [
  {
    nombre: 'Gasolinera Demo Norte', ubicacion: 'Quito, sector Norte',
    problemas: "Retraso ocasional en la llegada del Diesel",
    riesgos: "Competencia de una gasolinera nueva a dos cuadras",
    compras: { 'Super' => [10_000, '2.40'], 'Diesel' => [8_000, '1.90'], 'Ecopaís' => [6_000, '2.30'] },
    ventas:  { 'Super' => [8_800, '2.80'],  'Diesel' => [6_400, '2.25'], 'Ecopaís' => [4_800, '2.65'] },
    fletes:  [['Trailer 1', 600], ['Trailer 2', 600]]
  },
  {
    nombre: 'Gasolinera Demo Centro', ubicacion: 'Ambato, Centro',
    problemas: "Bajas ventas de Ecopaís\nBomba de Diesel con fallas",
    riesgos: "Cierre de vías por obras",
    compras: { 'Super' => [8_000, '2.40'], 'Diesel' => [6_000, '1.90'], 'Ecopaís' => [3_000, '2.30'] },
    ventas:  { 'Super' => [5_200, '2.62'], 'Diesel' => [3_600, '2.04'], 'Ecopaís' => [1_800, '2.50'] },
    fletes:  [['Trailer 1', 800]]
  },
  {
    nombre: 'Gasolinera Demo Sur', ubicacion: 'Guayaquil, vía a la costa',
    problemas: "Tanques con fugas\nPocos clientes por la tarde",
    riesgos: "Robos en la zona\nAumento del precio del combustible",
    compras: { 'Super' => [9_000, '2.40'], 'Diesel' => [7_000, '1.90'] },
    ventas:  { 'Super' => [3_000, '2.45'], 'Diesel' => [2_000, '1.95'] },
    fletes:  [['Trailer 1', 900], ['Trailer 2', 900]]
  }
].freeze

# ---------- Carga en la base de datos ----------
if defined?(ActiveRecord)
  usuario = User.find_or_initialize_by(email: DEMO_USUARIO[:email])
  if usuario.new_record?
    usuario.password = usuario.password_confirmation = DEMO_USUARIO[:password]
    usuario.save!
  end

  DEMO_GASOLINERAS.each do |datos|
    next if usuario.gasolineras.exists?(nombre: datos[:nombre])

    g = usuario.gasolineras.create!(
      nombre: datos[:nombre], ubicacion: datos[:ubicacion],
      problemas: datos[:problemas], riesgos: datos[:riesgos]
    )
    datos[:compras].each { |comb, (gal, precio)| g.compras.create!(combustible: comb, galones: gal, precio: precio) }
    datos[:ventas].each  { |comb, (gal, precio)| g.ventas.create!(combustible: comb, galones: gal, precio: precio) }
    datos[:fletes].each  { |desc, valor| g.fletes.create!(descripcion: desc, valor: valor) }
  end

  puts "Datos de demostración listos (usuario: #{DEMO_USUARIO[:email]})"
end
