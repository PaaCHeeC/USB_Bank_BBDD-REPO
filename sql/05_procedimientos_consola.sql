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
            LPAD('Comision', w_com),
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
            LPAD('Comision', 10),
            LPAD('Nro Movimientos', 15),
            LPAD('Total Cuentas BBDD', 18),
            LPAD('Mov Ecommerce', 14),
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
            RPAD('Canal Descripcion', 30),
            LPAD('Onboardings', 12),
            LPAD('Ingresos', 11),
            LPAD('Egresos', 11),
            LPAD('Neto', 11),
            LPAD('Comisiones', 11),
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
            LPAD('Comisiones', 10),
            LPAD('Nro Movimientos', 15),
            LPAD('Mov Ecommerce', 14),
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
