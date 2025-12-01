

/* ============================================================
   CASO 1 – INFORME DE PROFESIONALES POR SECTOR
   ============================================================ */

/* =============================
   BANCA (cód. sector = 3)
   ============================= */

SELECT
    p.id_profesional,
    p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre AS nombre_completo,
    COUNT(*) AS cant_banca,
    SUM(a.honorario) AS total_banca
FROM profesional p
JOIN asesoria a
    ON p.id_profesional = a.id_profesional
JOIN empresa e
    ON a.cod_empresa = e.cod_empresa
JOIN sector s
    ON e.cod_sector = s.cod_sector
WHERE s.cod_sector = 3
GROUP BY
    p.id_profesional,
    p.appaterno,
    p.apmaterno,
    p.nombre
ORDER BY
    p.id_profesional;


/* =============================
   RETAIL (cód. sector = 4)
   ============================= */

SELECT
    p.id_profesional,
    p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre AS nombre_completo,
    COUNT(*) AS cant_retail,
    SUM(a.honorario) AS total_retail
FROM profesional p
JOIN asesoria a
    ON p.id_profesional = a.id_profesional
JOIN empresa e
    ON a.cod_empresa = e.cod_empresa
JOIN sector s
    ON e.cod_sector = s.cod_sector
WHERE s.cod_sector = 4
GROUP BY
    p.id_profesional,
    p.appaterno,
    p.apmaterno,
    p.nombre
ORDER BY
    p.id_profesional;


/* ============================================================
   CASO 2 – REPORTE MENSUAL ABRIL AÑO PASADO
   ============================================================ */

/* 1. Crear la tabla de reporte */

DROP TABLE reporte_mes PURGE;

CREATE TABLE reporte_mes (
    id_profesional       NUMBER,
    nombre_completo      VARCHAR2(200),
    profesion            VARCHAR2(100),
    comuna               VARCHAR2(100),
    cant_asesorias       NUMBER,
    total_honorarios     NUMBER,
    promedio_honorarios  NUMBER,
    honorario_min        NUMBER,
    honorario_max        NUMBER
);


/* 2. Insertar datos desde el SELECT */

INSERT INTO reporte_mes (
    id_profesional,
    nombre_completo,
    profesion,
    comuna,
    cant_asesorias,
    total_honorarios,
    promedio_honorarios,
    honorario_min,
    honorario_max
)
SELECT
    p.id_profesional,
    p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre AS nombre_completo,
    pr.nombre_profesion AS profesion,
    c.nom_comuna AS comuna,
    COUNT(a.honorario) AS cant_asesorias,
    NVL(SUM(a.honorario), 0) AS total_honorarios,
    NVL(ROUND(AVG(a.honorario), 0), 0) AS promedio_honorarios,
    NVL(MIN(a.honorario), 0) AS honorario_min,
    NVL(MAX(a.honorario), 0) AS honorario_max
FROM profesional p
JOIN profesion pr
    ON p.cod_profesion = pr.cod_profesion
JOIN comuna c
    ON p.cod_comuna = c.cod_comuna
JOIN asesoria a
    ON p.id_profesional = a.id_profesional
WHERE a.inicio_asesoria BETWEEN 
      ADD_MONTHS(TRUNC(SYSDATE, 'YYYY'), -9)      -- 01/04/año pasado
  AND ADD_MONTHS(TRUNC(SYSDATE, 'YYYY'), -8) - 1  -- 30/04/año pasado
GROUP BY 
    p.id_profesional,
    p.appaterno,
    p.apmaterno,
    p.nombre,
    pr.nombre_profesion,
    c.nom_comuna
ORDER BY 
    p.id_profesional;

COMMIT;


/* 3. Visualizar datos cargados */

SELECT *
FROM reporte_mes
ORDER BY id_profesional;


/* ============================================================
   CASO 3 – AUMENTO DE SUELDOS SEGÚN DESEMPEÑO
   ============================================================ */

/* 1. Reporte ANTES del aumento */

SELECT
    p.id_profesional,
    p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre AS nombre_completo,
    p.sueldo AS sueldo_actual,
    NVL(SUM(a.honorario), 0) AS total_marzo_anio_pasado
FROM profesional p
LEFT JOIN asesoria a
    ON p.id_profesional = a.id_profesional
    AND a.inicio_asesoria BETWEEN 
        ADD_MONTHS(TRUNC(SYSDATE, 'YYYY'), -10)     -- 01/03/año pasado
    AND ADD_MONTHS(TRUNC(SYSDATE, 'YYYY'), -9) - 1  -- 31/03/año pasado
GROUP BY
    p.id_profesional,
    p.appaterno,
    p.apmaterno,
    p.nombre,
    p.sueldo
ORDER BY
    p.id_profesional;


/* 2. Aplicar el aumento según condición */

UPDATE profesional p
SET p.sueldo =
    p.sueldo * (
        CASE
            WHEN (
                SELECT NVL(SUM(a.honorario), 0)
                FROM asesoria a
                WHERE a.id_profesional = p.id_profesional
                AND a.inicio_asesoria BETWEEN 
                    ADD_MONTHS(TRUNC(SYSDATE, 'YYYY'), -10)
                AND ADD_MONTHS(TRUNC(SYSDATE, 'YYYY'), -9) - 1
            ) < 1000000
            THEN 1.10   -- aumenta 10%
            ELSE 1.15   -- aumenta 15%
        END
    );

COMMIT;


/* 3. Reporte DESPUÉS del aumento */

SELECT
    p.id_profesional,
    p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre AS nombre_completo,
    p.sueldo AS sueldo_actualizado
FROM profesional p
ORDER BY p.id_profesional;


