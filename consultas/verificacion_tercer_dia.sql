-- 1) Registros del tercer dia (deben ser 6)
SELECT fecha, id_envio, ciudad, transportadora, estado, duracion_minutos
FROM entregas
WHERE fecha = '2026-10-03'
ORDER BY id_envio;

-- 2) Conteo por estado del tercer dia
SELECT fecha, estado, COUNT(*) AS total_intentos
FROM entregas
WHERE fecha = '2026-10-03'
GROUP BY fecha, estado
ORDER BY estado;

-- 3) Total de registros de la tabla (deben ser 18)
SELECT COUNT(*) AS total_registros
FROM entregas;