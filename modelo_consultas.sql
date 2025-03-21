-- 1. Crear la tabla entidad
CREATE TABLE entidad (
    id_entidad SERIAL PRIMARY KEY,
    nombre_entidad TEXT NOT NULL,
    nivel TEXT,          -- Corresponde a "Nivel Entidad"
    orden TEXT,          -- Corresponde a "Orden Entidad"
    indicador TEXT,      -- Atributo adicional para indicador (si aplica)
    nit TEXT NOT NULL,   -- NIT de la entidad
    UNIQUE(nombre_entidad, nit)
);

-- 2. Crear la tabla contrato
CREATE TABLE contrato (
    numero_contrato TEXT PRIMARY KEY,
    numero_contratista TEXT,
    tipo_contratante TEXT,
    anio_firma TEXT,         -- Puede ser texto o número, según el formato del Excel
    contratista_id TEXT,
    contratista_nombre TEXT,
    fecha_firma DATE,
    plazo INTEGER,
    fecha_fin DATE
);

-- 3. Crear la tabla modalidad
CREATE TABLE modalidad (
    id_modalidad INTEGER PRIMARY KEY,
    modalidad_de_contratacion TEXT NOT NULL,
    causal_de_otras_formas_de TEXT
);

-- 4. Crear la tabla UNSPSC
CREATE TABLE unspsc (
    codigo TEXT PRIMARY KEY,
    nombre TEXT NOT NULL,
    detalle TEXT
);

-- 5. Crear la tabla proceso (tabla principal)
CREATE TABLE proceso (
    numero_constancia TEXT PRIMARY KEY,
    tipo_proceso TEXT NOT NULL,
    estado_proceso TEXT NOT NULL,
    valor_contrato NUMERIC,
    id_entidad INTEGER NOT NULL,
    id_modalidad INTEGER NOT NULL,
    unspsc_codigo TEXT NOT NULL,
    numero_de_contrato TEXT,  -- Puede ser nulo si no hay contrato asociado
    CONSTRAINT fk_proceso_entidad FOREIGN KEY (id_entidad) REFERENCES entidad(id_entidad),
    CONSTRAINT fk_proceso_modalidad FOREIGN KEY (id_modalidad) REFERENCES modalidad(id_modalidad),
    CONSTRAINT fk_proceso_unspsc FOREIGN KEY (unspsc_codigo) REFERENCES unspsc(codigo),
    CONSTRAINT fk_proceso_contrato FOREIGN KEY (numero_de_contrato) REFERENCES contrato(numero_contrato)
);

select * from unspsc;

SELECT e.id_entidad, e.nombre_entidad
FROM entidad e
LEFT JOIN proceso p 
  ON e.id_entidad = p.id_entidad 
  AND LOWER(p.tipo_proceso) LIKE '%licitacion%'
WHERE p.numero_constancia IS NULL;

SELECT 
    p.numero_constancia,
    p.tipo_proceso,
    p.estado_proceso,
    p.valor_contrato,
    e.nombre_entidad,
    m.modalidad_de_contratacion,
    u.nombre AS unspsc_nombre,
    c.numero_contrato,
    c.fecha_firma
FROM proceso p
INNER JOIN entidad e ON p.id_entidad = e.id_entidad
INNER JOIN modalidad m ON p.id_modalidad = m.id_modalidad
INNER JOIN unspsc u ON p.unspsc_codigo = u.codigo
LEFT JOIN contrato c ON p.numero_de_contrato = c.numero_contrato;
;

SELECT e.id_entidad, e.nombre_entidad, COUNT(p.numero_constancia) AS total_procesos
FROM proceso p
JOIN entidad e 
  ON p.id_entidad = e.id_entidad
JOIN unspsc u 
  ON p.unspsc_codigo = u.codigo
WHERE u.codigo = '43000000'
GROUP BY e.id_entidad, e.nombre_entidad
HAVING COUNT(p.numero_constancia) >= 3;


WITH estados AS (
    SELECT DISTINCT estado_proceso 
    FROM proceso
)
SELECT 
    e.estado_proceso, 
    u.codigo AS producto_codigo, 
    u.nombre AS producto_nombre,
    COUNT(p.numero_constancia) AS total_procesos
FROM estados e
CROSS JOIN unspsc u
LEFT JOIN proceso p 
    ON p.estado_proceso = e.estado_proceso 
   AND p.unspsc_codigo = u.codigo
GROUP BY e.estado_proceso, u.codigo, u.nombre
ORDER BY e.estado_proceso, total_procesos DESC;


SELECT 
    e.id_entidad, 
    e.nombre_entidad, 
    p.tipo_proceso,
    SUM(p.valor_contrato) AS total_contratado
FROM proceso p
JOIN entidad e 
  ON p.id_entidad = e.id_entidad
GROUP BY e.id_entidad, e.nombre_entidad, p.tipo_proceso
ORDER BY e.id_entidad, p.tipo_proceso;


SELECT 
    u.codigo AS producto_codigo, 
    u.nombre AS producto_nombre, 
    SUM(p.valor_contrato) AS total_contratado
FROM proceso p
JOIN unspsc u 
  ON p.unspsc_codigo = u.codigo
GROUP BY u.codigo, u.nombre
ORDER BY total_contratado DESC
LIMIT 5;

