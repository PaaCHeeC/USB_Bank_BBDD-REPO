SET search_path TO "usb_bank";

-- Reporte estadistico actualizado para reflejar el formato actual.
CREATE OR REPLACE PROCEDURE "usb_bank"."sp_imprimir_reporte_estadistico"(
    p_fecha_inicio DATE DEFAULT NULL,
    p_fecha_fin DATE DEFAULT NULL,
    p_tipo_cliente TEXT DEFAULT 'Todos',
    p_canal_onboarding TEXT DEFAULT 'Todos'
)
LANGUAGE plpgsql
AS $$
DECLARE
    registro RECORD;
    ancho_id CONSTANT INT := 6;
    ancho_titular CONSTANT INT := 30;
    ancho_tipo CONSTANT INT := 12;
    ancho_canal CONSTANT INT := 16;
    ancho_cuentas CONSTANT INT := 14;
    ancho_tarjetas CONSTANT INT := 15;
    ancho_fecha CONSTANT INT := 12;
    ancho_debe CONSTANT INT := 10;
    ancho_haber CONSTANT INT := 10;
    ancho_saldo CONSTANT INT := 15;
    linea_separadora TEXT;
    v_total_ingresos NUMERIC := 0;
    v_total_egresos NUMERIC := 0;
    v_balance_neto NUMERIC := 0;
    v_total_clientes_activos BIGINT := 0;
    v_total_cuentas_activas BIGINT := 0;
    v_total_tarjetas_activas BIGINT := 0;
    v_onboarding_portal_web BIGINT := 0;
    v_onboarding_app_movil BIGINT := 0;
    v_rango_fechas TEXT;
BEGIN
    linea_separadora := REPEAT(
        '-',
        ancho_id + ancho_titular + ancho_tipo + ancho_canal + ancho_cuentas +
        ancho_tarjetas + ancho_fecha + ancho_debe + ancho_haber + ancho_saldo + 31
    );

    RAISE NOTICE '%', linea_separadora;
    RAISE NOTICE '| % | % | % | % | % | % | % | % | % | % |',
        RPAD('ID', ancho_id),
        RPAD('Titular', ancho_titular),
        RPAD('Tipo Cliente', ancho_tipo),
        RPAD('Canal Onboarding', ancho_canal),
        LPAD('Total Cuentas', ancho_cuentas),
        LPAD('Total Tarjetas', ancho_tarjetas),
        RPAD('Fecha Registro', ancho_fecha),
        LPAD('Debe', ancho_debe),
        LPAD('Haber', ancho_haber),
        LPAD('Saldo Total', ancho_saldo);
    RAISE NOTICE '%', linea_separadora;

    FOR registro IN (
        WITH base_clientes AS (
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
                END AS "Canal_Onboarding",
                COALESCE(cu.cuentas, 0) AS "Total_Cuentas",
                COALESCE(tj.tarjetas, 0) AS "Total_Tarjetas",
                c.fecha_registro::DATE AS "Fecha_Registro",
                COALESCE(cu.saldo_total_cuenta, 0.00) AS "Saldo_Total"
            FROM "usb_bank"."CLIENTE" c
            LEFT JOIN "usb_bank"."CLIENTE_NATURAL" cn ON c.id_cliente = cn.id_cliente
            LEFT JOIN "usb_bank"."CLIENTE_JURIDICO" cj ON c.id_cliente = cj.id_cliente
            JOIN "usb_bank"."CANAL" can ON c.id_canal_onboarding = can.id_canal
            LEFT JOIN (
                SELECT id_cliente, SUM(saldo) AS saldo_total_cuenta, COUNT(id_cliente) AS cuentas
                FROM "usb_bank"."CUENTA"
                GROUP BY id_cliente
            ) cu ON c.id_cliente = cu.id_cliente
            LEFT JOIN (
                SELECT cu2.id_cliente, COUNT(DISTINCT t2.nro_tarjeta) AS tarjetas
                FROM "usb_bank"."CUENTA" cu2
                JOIN "usb_bank"."TARJETA" t2 ON cu2.nro_cuenta = t2.nro_cuenta
                GROUP BY cu2.id_cliente
            ) tj ON c.id_cliente = tj.id_cliente
        ),
        movimientos_por_cliente AS (
            WITH movimientos_filtrados AS (
                SELECT m.*
                FROM "usb_bank"."MOVIMIENTO" m
                WHERE (p_fecha_inicio IS NULL OR m.fecha >= p_fecha_inicio::timestamp)
                  AND (p_fecha_fin IS NULL OR m.fecha < (p_fecha_fin + INTERVAL '1 day'))
            ),
            movimientos_unificados AS (
                SELECT m.nro_cuenta_origen AS nro_cuenta, m.monto_egreso AS egreso, 0.00::numeric AS ingreso
                FROM movimientos_filtrados m
                UNION ALL
                SELECT m.nro_cuenta_destino AS nro_cuenta, 0.00::numeric AS egreso, m.monto_ingreso AS ingreso
                FROM movimientos_filtrados m
            )
            SELECT
                cu_mov.id_cliente,
                COALESCE(SUM(mu.ingreso), 0.00) AS debe,
                COALESCE(SUM(mu.egreso), 0.00) AS haber
            FROM movimientos_unificados mu
            JOIN "usb_bank"."CUENTA" cu_mov ON mu.nro_cuenta = cu_mov.nro_cuenta
            WHERE (mu.ingreso + mu.egreso) > 0
            GROUP BY cu_mov.id_cliente
        )
        SELECT
            bc."ID_Cliente",
            bc."Titular",
            bc."Tipo_Cliente",
            bc."Canal_Onboarding",
            bc."Total_Cuentas",
            bc."Total_Tarjetas",
            bc."Fecha_Registro",
            COALESCE(mp.debe, 0.00) AS debe,
            COALESCE(mp.haber, 0.00) AS haber,
            bc."Saldo_Total"
        FROM base_clientes bc
        LEFT JOIN movimientos_por_cliente mp ON bc."ID_Cliente" = mp.id_cliente
        WHERE (LOWER(COALESCE(p_tipo_cliente, 'Todos')) = 'todos' OR bc."Tipo_Cliente" = p_tipo_cliente)
          AND (LOWER(COALESCE(p_canal_onboarding, 'Todos')) = 'todos' OR bc."Canal_Onboarding" = p_canal_onboarding)
        ORDER BY bc."ID_Cliente"
    ) LOOP
        RAISE NOTICE '| % | % | % | % | % | % | % | % | % | % |',
            LPAD(registro."ID_Cliente"::TEXT, ancho_id),
            RPAD(COALESCE(SUBSTRING(registro."Titular", 1, ancho_titular), ''), ancho_titular),
            RPAD(COALESCE(registro."Tipo_Cliente", ''), ancho_tipo),
            RPAD(COALESCE(registro."Canal_Onboarding", ''), ancho_canal),
            LPAD(COALESCE(registro."Total_Cuentas", 0)::TEXT, ancho_cuentas),
            LPAD(COALESCE(registro."Total_Tarjetas", 0)::TEXT, ancho_tarjetas),
            RPAD(COALESCE(TO_CHAR(registro."Fecha_Registro", 'YYYY-MM-DD'), ''), ancho_fecha),
            LPAD(REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(registro.debe, 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.'), ancho_debe),
            LPAD(REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(registro.haber, 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.'), ancho_haber),
            LPAD(REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(registro."Saldo_Total", 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.'), ancho_saldo);
    END LOOP;

    RAISE NOTICE '%', linea_separadora;

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
        COALESCE(SUM(mu.ingreso), 0.00),
        COALESCE(SUM(mu.egreso), 0.00)
    INTO v_total_ingresos, v_total_egresos
    FROM movimientos_unificados mu
    JOIN "usb_bank"."CUENTA" cu_mov ON mu.nro_cuenta = cu_mov.nro_cuenta
    WHERE (mu.ingreso + mu.egreso) > 0;

    v_balance_neto := v_total_ingresos - v_total_egresos;

    SELECT
        COUNT(*) FILTER (WHERE LOWER(c.estado) = 'activo'),
        (SELECT COUNT(*) FROM "usb_bank"."CUENTA" cu WHERE LOWER(cu.estado) = 'activa'),
        (SELECT COUNT(*) FROM "usb_bank"."TARJETA" t WHERE LOWER(t.estado) = 'activa'),
        COUNT(*) FILTER (WHERE LOWER(can.descripcion) LIKE '%portal web%'),
        COUNT(*) FILTER (WHERE LOWER(can.descripcion) LIKE '%app movil%')
    INTO
        v_total_clientes_activos,
        v_total_cuentas_activas,
        v_total_tarjetas_activas,
        v_onboarding_portal_web,
        v_onboarding_app_movil
    FROM "usb_bank"."CLIENTE" c
    JOIN "usb_bank"."CANAL" can ON can.id_canal = c.id_canal_onboarding
    WHERE LOWER(c.estado) = 'activo';

    v_rango_fechas := CASE
        WHEN p_fecha_inicio IS NULL AND p_fecha_fin IS NULL THEN 'Todos los registros hasta la fecha'
        ELSE FORMAT(
            'Desde %s Hasta %s',
            COALESCE(TO_CHAR(p_fecha_inicio, 'YYYY-MM-DD'), 'N/A'),
            COALESCE(TO_CHAR(p_fecha_fin, 'YYYY-MM-DD'), 'N/A')
        )
    END;

    RAISE NOTICE '';
    RAISE NOTICE 'Resumen de Operaciones (%)', v_rango_fechas;
    RAISE NOTICE '-----------------------------------------------------------';
    RAISE NOTICE 'TOTAL GENERAL DE INGRESOS (DEBE): VES %',
        REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(v_total_ingresos, 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.');
    RAISE NOTICE 'TOTAL GENERAL DE EGRESOS (HABER): VES %',
        REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(v_total_egresos, 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.');
    RAISE NOTICE 'BALANCE NETO DEL PERIODO: VES %',
        REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(v_balance_neto, 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.');

    RAISE NOTICE '';
    RAISE NOTICE 'Información del Sistema';
    RAISE NOTICE '-----------------------';
    RAISE NOTICE 'TOTAL CLIENTES ACTIVOS: %', COALESCE(v_total_clientes_activos, 0);
    RAISE NOTICE 'TOTAL CUENTAS ACTIVAS: %', COALESCE(v_total_cuentas_activas, 0);
    RAISE NOTICE 'TOTAL TARJETAS ACTIVAS: %', COALESCE(v_total_tarjetas_activas, 0);
    RAISE NOTICE 'Onboarding por Canal - Portal Web: % clientes', COALESCE(v_onboarding_portal_web, 0);
    RAISE NOTICE 'Onboarding por Canal - App Móvil: % clientes', COALESCE(v_onboarding_app_movil, 0);
END;
$$;

CREATE OR REPLACE PROCEDURE "usb_bank"."sp_imprimir_reporte_contable"(
    p_agrupar_por TEXT DEFAULT 'cliente',
    p_fecha_inicio DATE DEFAULT NULL,
    p_fecha_fin DATE DEFAULT NULL,
    p_estado TEXT DEFAULT 'Todos'
)
LANGUAGE plpgsql
AS $$
DECLARE
    registro RECORD;
    w_id CONSTANT INT := 4;
    w_tit CONSTANT INT := 30;
    w_est CONSTANT INT := 8;
    w_cue_act CONSTANT INT := 19;
    w_tar_act CONSTANT INT := 20;
    w_ing CONSTANT INT := 9;
    w_egr CONSTANT INT := 9;
    w_net CONSTANT INT := 11;
    w_com CONSTANT INT := 9;
    w_nro_mov CONSTANT INT := 15;
    w_mov_ecom CONSTANT INT := 19;
    w_mov_pm CONSTANT INT := 15;
    w_mov_pos CONSTANT INT := 12;
    w_mov_atm CONSTANT INT := 14;
    w_mov_trans CONSTANT INT := 18;
    linea_separadora TEXT;
    v_total_ingresos NUMERIC := 0;
    v_total_egresos NUMERIC := 0;
    v_balance_neto NUMERIC := 0;
    v_total_comisiones NUMERIC := 0;
    v_movimientos_analizados BIGINT := 0;
    v_total_clientes_activos BIGINT := 0;
    v_total_cuentas_activas BIGINT := 0;
    v_total_tarjetas_activas BIGINT := 0;
BEGIN
    IF LOWER(COALESCE(p_agrupar_por, 'cliente')) = 'cliente' THEN
        linea_separadora := REPEAT(
            '-',
            w_id + w_tit + w_est + w_cue_act + w_tar_act + w_ing + w_egr + w_net + w_com +
            w_nro_mov + w_mov_ecom + w_mov_pm + w_mov_pos + w_mov_atm + w_mov_trans + 46
        );

        RAISE NOTICE '%', linea_separadora;
        RAISE NOTICE '| % | % | % | % | % | % | % | % | % | % | % | % | % | % | % |',
            RPAD('ID', w_id),
            RPAD('Titular', w_tit),
            RPAD('Estado', w_est),
            LPAD('Nro Cuentas Activas', w_cue_act),
            LPAD('Nro Tarjetas Activas', w_tar_act),
            LPAD('Ingresos', w_ing),
            LPAD('Egresos', w_egr),
            LPAD('Neto', w_net),
            LPAD('Comisión', w_com),
            LPAD('Nro Movimientos', w_nro_mov),
            LPAD('Mov Pago Ecommerce', w_mov_ecom),
            LPAD('Mov Pago Movil', w_mov_pm),
            LPAD('Mov Pago POS', w_mov_pos),
            LPAD('Mov Retiro ATM', w_mov_atm),
            LPAD('Mov Transferencia', w_mov_trans);
        RAISE NOTICE '%', linea_separadora;

        FOR registro IN (
            SELECT *
            FROM "usb_bank"."fn_reporte_contable_cliente"(p_fecha_inicio, p_fecha_fin, p_estado)
        ) LOOP
            RAISE NOTICE '| % | % | % | % | % | % | % | % | % | % | % | % | % | % | % |',
                LPAD(COALESCE(registro."ID", 0)::TEXT, w_id),
                RPAD(COALESCE(SUBSTRING(registro."Titular", 1, w_tit), ''), w_tit),
                RPAD(COALESCE(registro."Estado", ''), w_est),
                LPAD(COALESCE(registro."Nro_Cuentas_Activas", 0)::TEXT, w_cue_act),
                LPAD(COALESCE(registro."Nro_Tarjetas_Activas", 0)::TEXT, w_tar_act),
                LPAD(REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(registro."Ingresos", 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.'), w_ing),
                LPAD(REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(registro."Egresos", 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.'), w_egr),
                LPAD(REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(registro."Neto", 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.'), w_net),
                LPAD(REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(registro."Comisiones", 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.'), w_com),
                LPAD(COALESCE(registro."Nro Movimientos", 0)::TEXT, w_nro_mov),
                LPAD(REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(registro."Mov_Pago_Ecommerce", 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.'), w_mov_ecom),
                LPAD(REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(registro."Mov_Pago_Movil", 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.'), w_mov_pm),
                LPAD(REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(registro."Mov_Pago_POS", 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.'), w_mov_pos),
                LPAD(REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(registro."Mov_Retiro_ATM", 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.'), w_mov_atm),
                LPAD(REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(registro."Mov Transferencia", 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.'), w_mov_trans);
        END LOOP;

        RAISE NOTICE '%', linea_separadora;

    ELSIF LOWER(p_agrupar_por) = 'cuenta' THEN
        linea_separadora := REPEAT('-', 225);
        RAISE NOTICE '%', linea_separadora;
        RAISE NOTICE '| % | % | % | % | % | % | % | % | % | % | % | % | % | % |',
            RPAD('Nro Cuenta', 20),
            RPAD('Titular', 30),
            RPAD('Estado', 8),
            LPAD('Ingresos', 10),
            LPAD('Egresos', 10),
            LPAD('Neto', 11),
            LPAD('Comisión', 10),
            LPAD('Nro Movimientos', 15),
            LPAD('Total Cuentas BBDD', 18),
            LPAD('Mov Pago Ecommerce', 14),
            LPAD('Mov Pago Movil', 14),
            LPAD('Mov POS', 10),
            LPAD('Mov ATM', 10),
            LPAD('Mov Transferencia', 18);
        RAISE NOTICE '%', linea_separadora;

        FOR registro IN (
            SELECT *
            FROM "usb_bank"."fn_reporte_contable_cuenta"(p_fecha_inicio, p_fecha_fin, p_estado)
        ) LOOP
            RAISE NOTICE '| % | % | % | % | % | % | % | % | % | % | % | % | % | % |',
                RPAD(COALESCE(registro."Nro_Cuenta", ''), 20),
                RPAD(COALESCE(SUBSTRING(registro."Titular", 1, 30), ''), 30),
                RPAD(COALESCE(registro."Estado", ''), 8),
                LPAD(REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(registro."Ingresos", 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.'), 10),
                LPAD(REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(registro."Egresos", 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.'), 10),
                LPAD(REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(registro."Neto", 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.'), 11),
                LPAD(REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(registro."Comisiones", 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.'), 10),
                LPAD(COALESCE(registro."Nro Movimientos", 0)::TEXT, 15),
                LPAD(COALESCE(registro."Total_Cuentas_Activas_BBDD", 0)::TEXT, 18),
                LPAD(REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(registro."Mov_Pago_Ecommerce", 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.'), 14),
                LPAD(REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(registro."Mov_Pago_Movil", 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.'), 14),
                LPAD(REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(registro."Mov_Pago_POS", 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.'), 10),
                LPAD(REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(registro."Mov_Retiro_ATM", 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.'), 10),
                LPAD(REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(registro."Mov Transferencia", 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.'), 18);
        END LOOP;

        RAISE NOTICE '%', linea_separadora;

    ELSIF LOWER(p_agrupar_por) = 'canal' THEN
        linea_separadora := REPEAT('-', 120);
        RAISE NOTICE '%', linea_separadora;
        RAISE NOTICE '| % | % | % | % | % | % | % |',
            RPAD('Canal Descripción', 30),
            LPAD('Onboardings', 12),
            LPAD('Ingresos', 11),
            LPAD('Egresos', 11),
            LPAD('Neto', 11),
            LPAD('Comisión', 11),
            LPAD('Nro Movimientos', 15);
        RAISE NOTICE '%', linea_separadora;

        FOR registro IN (
            SELECT *
            FROM "usb_bank"."fn_reporte_contable_canal"(p_fecha_inicio, p_fecha_fin, p_estado)
        ) LOOP
            RAISE NOTICE '| % | % | % | % | % | % | % |',
                RPAD(COALESCE(SUBSTRING(registro."Canal_Descripcion", 1, 30), ''), 30),
                LPAD(COALESCE(registro."Onboardings_Canal", 0)::TEXT, 12),
                LPAD(REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(registro."Ingresos", 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.'), 11),
                LPAD(REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(registro."Egresos", 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.'), 11),
                LPAD(REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(registro."Neto", 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.'), 11),
                LPAD(REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(registro."Comisiones", 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.'), 11),
                LPAD(COALESCE(registro."Nro Movimientos", 0)::TEXT, 15);
        END LOOP;

        RAISE NOTICE '%', linea_separadora;

    ELSIF LOWER(p_agrupar_por) = 'tarjeta' THEN
        linea_separadora := REPEAT('-', 180);
        RAISE NOTICE '%', linea_separadora;
        RAISE NOTICE '| % | % | % | % | % | % | % | % | % | % | % | % |',
            RPAD('Nro Tarjeta', 16),
            RPAD('Titular', 30),
            RPAD('Tipo Tarjeta', 12),
            RPAD('Estado', 8),
            LPAD('Ingresos', 10),
            LPAD('Egresos', 10),
            LPAD('Neto', 10),
            LPAD('Comisión', 10),
            LPAD('Nro Movimientos', 15),
            LPAD('Mov Pago Ecommerce', 14),
            LPAD('Mov POS', 10),
            LPAD('Mov ATM', 10);
        RAISE NOTICE '%', linea_separadora;

        FOR registro IN (
            SELECT *
            FROM "usb_bank"."fn_reporte_contable_tarjeta"(p_fecha_inicio, p_fecha_fin, p_estado)
        ) LOOP
            RAISE NOTICE '| % | % | % | % | % | % | % | % | % | % | % | % |',
                RPAD(COALESCE(registro."Nro_Tarjeta", ''), 16),
                RPAD(COALESCE(SUBSTRING(registro."Titular", 1, 30), ''), 30),
                RPAD(COALESCE(registro."Tipo_Tarjeta", ''), 12),
                RPAD(COALESCE(registro."Estado", ''), 8),
                LPAD(REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(registro."Ingresos", 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.'), 10),
                LPAD(REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(registro."Egresos", 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.'), 10),
                LPAD(REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(registro."Neto", 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.'), 10),
                LPAD(REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(registro."Comisiones", 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.'), 10),
                LPAD(COALESCE(registro."Nro Movimientos", 0)::TEXT, 15),
                LPAD(REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(registro."Mov_Pago_Ecommerce", 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.'), 14),
                LPAD(REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(registro."Mov_Pago_POS", 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.'), 10),
                LPAD(REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(registro."Mov_Retiro_ATM", 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.'), 10);
        END LOOP;

        RAISE NOTICE '%', linea_separadora;
    ELSE
        RAISE EXCEPTION 'agrupar_por invalido: %. Use cliente, cuenta, canal o tarjeta.', p_agrupar_por;
    END IF;

    SELECT
        COALESCE(SUM(d."Ingreso"), 0.00),
        COALESCE(SUM(d."Egreso"), 0.00),
        COALESCE(SUM(d."Comision"), 0.00),
        COALESCE(COUNT(DISTINCT d."Referencia"), 0),
        COALESCE(MAX(d."Total_Clientes_Activos_BBDD"), 0),
        COALESCE(MAX(d."Total_Cuentas_Activas_BBDD"), 0),
        COALESCE(MAX(d."Total_Tarjetas_Activas_BBDD"), 0)
    INTO
        v_total_ingresos,
        v_total_egresos,
        v_total_comisiones,
        v_movimientos_analizados,
        v_total_clientes_activos,
        v_total_cuentas_activas,
        v_total_tarjetas_activas
    FROM "usb_bank"."fn_reporte_contable_detalle"(p_fecha_inicio, p_fecha_fin, p_estado) d;

    v_balance_neto := v_total_ingresos - v_total_egresos;

    RAISE NOTICE '';
    RAISE NOTICE 'TOTAL GENERAL DE INGRESOS (DEBE): VES %',
        REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(v_total_ingresos, 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.');
    RAISE NOTICE 'TOTAL GENERAL DE EGRESOS (HABER): VES %',
        REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(v_total_egresos, 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.');
    RAISE NOTICE 'BALANCE NETO DEL PERIODO: VES %',
        REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(v_balance_neto, 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.');
    RAISE NOTICE 'TOTAL COMISIONES: VES %',
        REPLACE(REPLACE(REPLACE(TO_CHAR(COALESCE(v_total_comisiones, 0), 'FM999,999,999,990.00'), ',', '_'), '.', ','), '_', '.');
    RAISE NOTICE 'MOVIMIENTOS ANALIZADOS: %', COALESCE(v_movimientos_analizados, 0);

    IF LOWER(COALESCE(p_agrupar_por, 'cliente')) = 'cliente' THEN
        RAISE NOTICE 'TOTAL CLIENTES ACTIVOS: %', COALESCE(v_total_clientes_activos, 0);
    ELSIF LOWER(p_agrupar_por) = 'cuenta' THEN
        RAISE NOTICE 'TOTAL CUENTAS ACTIVAS: %', COALESCE(v_total_cuentas_activas, 0);
    ELSIF LOWER(p_agrupar_por) = 'tarjeta' THEN
        RAISE NOTICE 'TOTAL TARJETAS ACTIVAS: %', COALESCE(v_total_tarjetas_activas, 0);
    END IF;
END;
$$;


-- Reporte de auditoria para salidas por consola.
CREATE OR REPLACE PROCEDURE "usb_bank"."sp_imprimir_reporte_auditoria"()
LANGUAGE plpgsql
AS $$
DECLARE
    registro RECORD;
    w_fecha CONSTANT INT := 20;
    w_id CONSTANT INT := 6;
    w_doc CONSTANT INT := 14;
    w_nombre CONSTANT INT := 32;
    w_cuentas CONSTANT INT := 9;
    total_eliminados INTEGER := 0;
    linea_separadora TEXT;
BEGIN
    linea_separadora := REPEAT('-', w_fecha + w_id + w_doc + w_nombre + w_cuentas + 16);

    RAISE NOTICE '%', linea_separadora;
    RAISE NOTICE '| % | % | % | % | % |',
        RPAD('Fecha Eliminacion', w_fecha),
        RPAD('ID', w_id),
        RPAD('Documento', w_doc),
        RPAD('Titular', w_nombre),
        LPAD('Cuentas', w_cuentas);
    RAISE NOTICE '%', linea_separadora;

    FOR registro IN (
        SELECT fecha_eliminacion, id_cliente, doc_cliente, nombre_cliente, cantidad_cuentas
        FROM "usb_bank"."REPORTE_CLIENTES_ELIMINADOS"
        ORDER BY fecha_eliminacion DESC, id_cliente
    ) LOOP
        total_eliminados := total_eliminados + 1;
        RAISE NOTICE '| % | % | % | % | % |',
            RPAD(TO_CHAR(registro.fecha_eliminacion, 'YYYY-MM-DD HH24:MI:SS'), w_fecha),
            LPAD(COALESCE(registro.id_cliente, 0)::TEXT, w_id),
            RPAD(COALESCE(registro.doc_cliente, 'N/A'), w_doc),
            RPAD(COALESCE(SUBSTRING(registro.nombre_cliente, 1, w_nombre), 'SIN NOMBRE'), w_nombre),
            LPAD(COALESCE(registro.cantidad_cuentas, 0)::TEXT, w_cuentas);
    END LOOP;

    RAISE NOTICE '%', linea_separadora;
    RAISE NOTICE 'TOTAL CLIENTES ELIMINADOS: %', total_eliminados;
END;
$$;

-- Ejemplos de llamada de los procedimientos:
-- CALL "usb_bank"."sp_imprimir_reporte_estadistico"();
-- CALL "usb_bank"."sp_imprimir_reporte_estadistico"('2020-01-01', '2026-12-31', 'Todos', 'Todos');

-- CALL "usb_bank"."sp_imprimir_reporte_contable"('cliente', NULL, NULL, 'Todos');
-- CALL "usb_bank"."sp_imprimir_reporte_auditoria"();
