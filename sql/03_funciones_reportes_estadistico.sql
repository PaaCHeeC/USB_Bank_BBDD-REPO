-- Función alineada a la consulta estadística usada en src/main.py.
-- Devuelve exactamente los campos base y KPIs que consumen los reportes.

SET search_path TO "usb_bank";

CREATE OR REPLACE FUNCTION "usb_bank"."fn_reporte_estadistico"(
    p_fecha_inicio DATE DEFAULT NULL,
    p_fecha_fin DATE DEFAULT NULL
)
RETURNS TABLE (
    "ID_Cliente" INTEGER,
    "Titular" TEXT,
    "Tipo_Cliente" VARCHAR(1),
    "Canal_Afiliacion" VARCHAR(1),
    "Total_Productos" BIGINT,
    "Saldo_Total" NUMERIC,
    "Fecha_Registro" DATE,
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
        COALESCE(cn.primer_nombre || ' ' || cn.apellido, cj.nombre_org) AS "Titular",
        CASE
            WHEN c.tipo_cliente = 'Natural' THEN 'N'
            ELSE 'J'
        END AS "Tipo_Cliente",
        CASE
            WHEN can.descripcion ILIKE '%Web%' THEN 'W'
            WHEN can.descripcion ILIKE '%Movil%' THEN 'M'
            ELSE 'O'
        END AS "Canal_Afiliacion",
        COALESCE(cu.cuentas, 0) AS "Total_Productos",
        COALESCE(cu.saldo_total_cuenta, 0.00) AS "Saldo_Total",
        c.fecha_registro::DATE AS "Fecha_Registro",
        kpi.total_clientes_activos AS "Total_Clientes_Activos",
        kpi.total_cuentas_activas AS "Total_Cuentas_Activas",
        kpi.total_tarjetas_activas AS "Total_Tarjetas_Activas",
        kpi.onboarding_portal_web AS "Onboarding_Portal_Web",
        kpi.onboarding_app_movil AS "Onboarding_App_Movil",
        kpi.onboarding_ivr_otros AS "Onboarding_IVR_Otros",
        COALESCE(mov.total_ingresos, 0.00) AS "Total_Ingresos_Periodo",
        COALESCE(mov.total_egresos, 0.00) AS "Total_Egresos_Periodo"
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
    LEFT JOIN (
        WITH movimientos_filtrados AS (
            SELECT m.*
            FROM "usb_bank"."MOVIMIENTO" m
            WHERE (p_fecha_inicio IS NULL OR m.fecha >= p_fecha_inicio::timestamp)
              AND (p_fecha_fin IS NULL OR m.fecha < (p_fecha_fin + INTERVAL '1 day'))
        ),
        movimientos_unificados AS (
            SELECT
                m.nro_cuenta_origen AS nro_cuenta,
                m.monto_egreso AS egreso,
                0.00::numeric AS ingreso
            FROM movimientos_filtrados m

            UNION ALL

            SELECT
                m.nro_cuenta_destino AS nro_cuenta,
                0.00::numeric AS egreso,
                m.monto_ingreso AS ingreso
            FROM movimientos_filtrados m
        )
        SELECT
            cu_mov.id_cliente,
            COALESCE(SUM(mu.ingreso), 0.00) AS total_ingresos,
            COALESCE(SUM(mu.egreso), 0.00) AS total_egresos
        FROM movimientos_unificados mu
        JOIN "usb_bank"."CUENTA" cu_mov ON mu.nro_cuenta = cu_mov.nro_cuenta
        WHERE (mu.ingreso + mu.egreso) > 0
        GROUP BY cu_mov.id_cliente
    ) mov ON c.id_cliente = mov.id_cliente
    ORDER BY c.id_cliente;
$$;
