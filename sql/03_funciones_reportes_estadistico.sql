-- Función alineada a la consulta estadística usada en src/main.py.
-- Devuelve exactamente los campos base y KPIs que consumen los reportes.

SET search_path TO "usb_bank";

CREATE OR REPLACE FUNCTION "usb_bank"."fn_reporte_estadistico"(
    p_fecha_inicio DATE DEFAULT NULL,
    p_fecha_fin DATE DEFAULT NULL
)
RETURNS TABLE (
    "ID_Cliente" INTEGER,
    "Nombre" TEXT,
    "Tipo_Cliente" VARCHAR(20),
    "Canal_Afiliacion" VARCHAR(50),
    "Total_Productos" BIGINT,
    "Saldo_Total" NUMERIC,
    "Fecha_Registro" TIMESTAMP,
    "Total_Clientes_Activos" BIGINT,
    "Total_Cuentas_Activas" BIGINT,
    "Total_Tarjetas_Activas" BIGINT,
    "Onboarding_Portal_Web" BIGINT,
    "Onboarding_App_Movil" BIGINT,
    "Onboarding_IVR_Otros" BIGINT,
    "Total_Ingresos_Periodo" NUMERIC,
    "Total_Egresos_Periodo" NUMERIC
)
LANGUAGE SQL
STABLE
AS $$
    SELECT
        c.id_cliente AS "ID_Cliente",
        COALESCE(cn.primer_nombre || ' ' || cn.apellido, cj.nombre_org) AS "Nombre",
        c.tipo_cliente AS "Tipo_Cliente",
        can.tipo_canal AS "Canal_Afiliacion",
        COALESCE(cu.cuentas, 0) AS "Total_Productos",
        COALESCE(cu.saldo_total_cuenta, 0.00) AS "Saldo_Total",
        c.fecha_registro AS "Fecha_Registro",
        kpi.total_clientes_activos AS "Total_Clientes_Activos",
        kpi.total_cuentas_activas AS "Total_Cuentas_Activas",
        kpi.total_tarjetas_activas AS "Total_Tarjetas_Activas",
        kpi.onboarding_portal_web AS "Onboarding_Portal_Web",
        kpi.onboarding_app_movil AS "Onboarding_App_Movil",
        kpi.onboarding_ivr_otros AS "Onboarding_IVR_Otros",
        mov.total_ingresos AS "Total_Ingresos_Periodo",
        mov.total_egresos AS "Total_Egresos_Periodo"
    FROM "usb_bank"."CLIENTE" c
    LEFT JOIN "usb_bank"."CLIENTE_NATURAL" cn ON c.id_cliente = cn.id_cliente
    LEFT JOIN "usb_bank"."CLIENTE_JURIDICO" cj ON c.id_cliente = cj.id_cliente
    JOIN "usb_bank"."CANAL" can ON c.id_canal_onboarding = can.id_canal
    LEFT JOIN (
        SELECT
            id_cliente,
            SUM(saldo) AS saldo_total_cuenta,
            COUNT(id_cliente) AS cuentas
        FROM "usb_bank"."CUENTA"
        GROUP BY id_cliente
    ) cu ON c.id_cliente = cu.id_cliente
    CROSS JOIN (
        SELECT
            COUNT(*) FILTER (WHERE LOWER(c2.estado) = 'activo') AS total_clientes_activos,
            (SELECT COUNT(*) FROM "usb_bank"."CUENTA" cu2 WHERE LOWER(cu2.estado) = 'activa') AS total_cuentas_activas,
            (SELECT COUNT(*) FROM "usb_bank"."TARJETA" t2 WHERE LOWER(t2.estado) = 'activa') AS total_tarjetas_activas,
            COUNT(*) FILTER (WHERE LOWER(can2.descripcion) LIKE '%portal web%') AS onboarding_portal_web,
            COUNT(*) FILTER (WHERE LOWER(can2.descripcion) LIKE '%app movil%') AS onboarding_app_movil,
            COUNT(*) FILTER (
                WHERE LOWER(can2.descripcion) NOT LIKE '%portal web%'
                  AND LOWER(can2.descripcion) NOT LIKE '%app movil%'
            ) AS onboarding_ivr_otros
        FROM "usb_bank"."CLIENTE" c2
        JOIN "usb_bank"."CANAL" can2 ON can2.id_canal = c2.id_canal_onboarding
        WHERE LOWER(c2.estado) = 'activo'
    ) kpi
    CROSS JOIN (
        SELECT
            COALESCE(SUM(m.monto_ingreso), 0.00) AS total_ingresos,
            COALESCE(SUM(m.monto_egreso), 0.00) AS total_egresos
        FROM "usb_bank"."MOVIMIENTO" m
        WHERE (p_fecha_inicio IS NULL OR m.fecha >= p_fecha_inicio::timestamp)
          AND (p_fecha_fin IS NULL OR m.fecha < (p_fecha_fin + INTERVAL '1 day'))
    ) mov
    ORDER BY c.id_cliente;
$$;
