-- Funciones SQL para reportes contables.
-- Estas funciones permiten ejecutar la logica de agregacion directamente en PostgreSQL.
-- Se pueden invocar desde psql o desde un procedimiento almacenado externo.

SET search_path TO "usb_bank";

-- Base reutilizable: normaliza movimientos y agrega campos de contexto.
CREATE OR REPLACE FUNCTION "usb_bank"."fn_reporte_contable_base"(
    p_fecha_inicio DATE DEFAULT NULL,
    p_fecha_fin DATE DEFAULT NULL,
    p_estado_movimiento TEXT DEFAULT 'Todos'
)
RETURNS TABLE (
    referencia VARCHAR(50),
    fecha_movimiento TIMESTAMP,
    estado_movimiento VARCHAR(20),
    direccion TEXT,
    nro_cuenta VARCHAR(20),
    id_cliente INTEGER,
    titular TEXT,
    estado_cliente VARCHAR(20),
    nro_cuentas_activas BIGINT,
    nro_tarjetas_activas BIGINT,
    tipo_cuenta VARCHAR(20),
    estado_cuenta VARCHAR(20),
    canal_descripcion VARCHAR(100),
    onboardings_canal BIGINT,
    nro_tarjeta VARCHAR(16),
    tipo_tarjeta VARCHAR(20),
    estado_tarjeta VARCHAR(20),
    tipo_movimiento VARCHAR(100),
    ingreso NUMERIC,
    egreso NUMERIC,
    comision NUMERIC,
    neto NUMERIC,
    monto_movido NUMERIC,
    total_clientes_activos_bbdd BIGINT,
    total_cuentas_activas_bbdd BIGINT,
    total_tarjetas_activas_bbdd BIGINT
)
LANGUAGE SQL
STABLE
AS $$
    WITH movimientos_filtrados AS (
        SELECT m.*
        FROM "usb_bank"."MOVIMIENTO" m
        WHERE (p_fecha_inicio IS NULL OR m.fecha >= p_fecha_inicio::timestamp)
          AND (p_fecha_fin IS NULL OR m.fecha < (p_fecha_fin + INTERVAL '1 day'))
          AND (
                LOWER(COALESCE(p_estado_movimiento, 'Todos')) = 'todos'
                OR LOWER(m.estado) = LOWER(p_estado_movimiento)
              )
    ),
    movimientos_unificados AS (
        SELECT
            m.nro_referencia,
            m.fecha,
            m.estado,
            m.id_canal,
            m.id_tipo_mov,
            m.id_banco_origen,
            m.id_banco_destino,
            m.descripcion_mov,
            m.monto_comision,
            m.nro_cuenta_origen AS nro_cuenta,
            'egreso'::text AS direccion,
            m.monto_egreso AS egreso,
            0.00::numeric AS ingreso,
            m.saldo_origen_previo AS saldo_previo,
            m.saldo_origen_nuevo AS saldo_nuevo
        FROM movimientos_filtrados m

        UNION ALL

        SELECT
            m.nro_referencia,
            m.fecha,
            m.estado,
            m.id_canal,
            m.id_tipo_mov,
            m.id_banco_origen,
            m.id_banco_destino,
            m.descripcion_mov,
            0.00::numeric AS monto_comision,
            m.nro_cuenta_destino AS nro_cuenta,
            'ingreso'::text AS direccion,
            0.00::numeric AS egreso,
            m.monto_ingreso AS ingreso,
            m.saldo_destino_previo AS saldo_previo,
            m.saldo_destino_nuevo AS saldo_nuevo
        FROM movimientos_filtrados m
    )
    SELECT
        mu.nro_referencia AS referencia,
        mu.fecha AS fecha_movimiento,
        mu.estado AS estado_movimiento,
        mu.direccion,
        mu.nro_cuenta,
        cu.id_cliente,
        COALESCE(cn.primer_nombre || ' ' || cn.apellido, cj.nombre_org, 'SIN TITULAR') AS titular,
        c.estado AS estado_cliente,
        COALESCE(cc.nro_cuentas_activas, 0) AS nro_cuentas_activas,
        COALESCE(tc.nro_tarjetas_activas, 0) AS nro_tarjetas_activas,
        cu.tipo_cuenta,
        cu.estado AS estado_cuenta,
        can_onb.descripcion AS canal_descripcion,
        COALESCE(ob.nro_onboardings, 0) AS onboardings_canal,
        COALESCE(pos.nro_tarjeta, ecom.nro_tarjeta, atm.nro_tarjeta, 'N/A') AS nro_tarjeta,
        COALESCE(t.tipo_tarjeta, 'N/A') AS tipo_tarjeta,
        COALESCE(t.estado, 'N/A') AS estado_tarjeta,
        tm.descripcion AS tipo_movimiento,
        mu.ingreso,
        mu.egreso,
        mu.monto_comision AS comision,
        (mu.ingreso - mu.egreso) AS neto,
        (mu.ingreso + mu.egreso) AS monto_movido,
        totales.total_clientes_activos,
        totales.total_cuentas_activas,
        totales.total_tarjetas_activas
    FROM movimientos_unificados mu
    JOIN "usb_bank"."CUENTA" cu ON mu.nro_cuenta = cu.nro_cuenta
    JOIN "usb_bank"."CLIENTE" c ON cu.id_cliente = c.id_cliente
    LEFT JOIN "usb_bank"."CLIENTE_NATURAL" cn ON c.id_cliente = cn.id_cliente
    LEFT JOIN "usb_bank"."CLIENTE_JURIDICO" cj ON c.id_cliente = cj.id_cliente
    LEFT JOIN (
        SELECT id_cliente, COUNT(DISTINCT nro_cuenta) AS nro_cuentas_activas
        FROM "usb_bank"."CUENTA"
        WHERE LOWER(estado) = 'activa'
        GROUP BY id_cliente
    ) cc ON cu.id_cliente = cc.id_cliente
    LEFT JOIN (
        SELECT cu2.id_cliente, COUNT(DISTINCT t2.nro_tarjeta) AS nro_tarjetas_activas
        FROM "usb_bank"."CUENTA" cu2
        LEFT JOIN "usb_bank"."TARJETA" t2
          ON cu2.nro_cuenta = t2.nro_cuenta
         AND LOWER(t2.estado) = 'activa'
        GROUP BY cu2.id_cliente
    ) tc ON cu.id_cliente = tc.id_cliente
    LEFT JOIN (
        SELECT id_canal_onboarding AS id_canal, COUNT(*) AS nro_onboardings
        FROM "usb_bank"."CLIENTE"
        WHERE LOWER(estado) = 'activo'
        GROUP BY id_canal_onboarding
    ) ob ON c.id_canal_onboarding = ob.id_canal
    CROSS JOIN (
        SELECT
            COUNT(*) FILTER (WHERE LOWER(c3.estado) = 'activo') AS total_clientes_activos,
            (SELECT COUNT(*) FROM "usb_bank"."CUENTA" cu3 WHERE LOWER(cu3.estado) = 'activa') AS total_cuentas_activas,
            (SELECT COUNT(*) FROM "usb_bank"."TARJETA" t3 WHERE LOWER(t3.estado) = 'activa') AS total_tarjetas_activas
        FROM "usb_bank"."CLIENTE" c3
    ) totales
    JOIN "usb_bank"."CANAL" can_onb ON c.id_canal_onboarding = can_onb.id_canal
    JOIN "usb_bank"."TIPO_MOVIMIENTO" tm ON mu.id_tipo_mov = tm.id_tipo_mov
    LEFT JOIN "usb_bank"."MOVIMIENTO_PAGO_POS" pos ON mu.nro_referencia = pos.nro_referencia
    LEFT JOIN "usb_bank"."MOVIMIENTO_PAGO_ECOMMERCE" ecom ON mu.nro_referencia = ecom.nro_referencia
    LEFT JOIN "usb_bank"."MOVIMIENTO_RETIRO_ATM" atm ON mu.nro_referencia = atm.nro_referencia
    LEFT JOIN "usb_bank"."TARJETA" t ON t.nro_tarjeta = COALESCE(pos.nro_tarjeta, ecom.nro_tarjeta, atm.nro_tarjeta)
    WHERE (mu.ingreso + mu.egreso) > 0;
$$;


-- Versión detallada equivalente al query de reporte contable de src/main.py.
CREATE OR REPLACE FUNCTION "usb_bank"."fn_reporte_contable_detalle"(
    p_fecha_inicio DATE DEFAULT NULL,
    p_fecha_fin DATE DEFAULT NULL,
    p_estado_movimiento TEXT DEFAULT 'Todos'
)
RETURNS TABLE (
    "Referencia" VARCHAR(50),
    "Fecha_Movimiento" TIMESTAMP,
    "Estado_Movimiento" VARCHAR(20),
    "Direccion" TEXT,
    "Cuenta" VARCHAR(20),
    "ID" INTEGER,
    "Titular" TEXT,
    "Estado_Cliente" VARCHAR(20),
    "Nro_Cuentas_Activas" BIGINT,
    "Nro_Tarjetas_Activas" BIGINT,
    "Tipo_Cuenta" VARCHAR(20),
    "Estado_Cuenta" VARCHAR(20),
    "Canal_Tx" VARCHAR(50),
    "Canal_Descripcion" VARCHAR(100),
    "Onboardings_Canal" BIGINT,
    "Tarjeta" VARCHAR(16),
    "Tipo_Tarjeta" VARCHAR(20),
    "Estado_Tarjeta" VARCHAR(20),
    "Marca_Tarjeta" VARCHAR(50),
    "Tipo_Movimiento" VARCHAR(100),
    "Ingreso" NUMERIC,
    "Egreso" NUMERIC,
    "Comision" NUMERIC,
    "Neto" NUMERIC,
    "Total_Clientes_Activos_BBDD" BIGINT,
    "Total_Cuentas_Activas_BBDD" BIGINT,
    "Total_Tarjetas_Activas_BBDD" BIGINT,
    "Saldo_Previo" NUMERIC,
    "Saldo_Nuevo" NUMERIC,
    "Banco_Origen" VARCHAR(100),
    "Banco_Destino" VARCHAR(100),
    "Descripcion_Movimiento" VARCHAR(255)
)
LANGUAGE SQL
STABLE
AS $$
    WITH movimientos_filtrados AS (
        SELECT m.*
        FROM "usb_bank"."MOVIMIENTO" m
        WHERE (p_fecha_inicio IS NULL OR m.fecha >= p_fecha_inicio::timestamp)
          AND (p_fecha_fin IS NULL OR m.fecha < (p_fecha_fin + INTERVAL '1 day'))
          AND (
                LOWER(COALESCE(p_estado_movimiento, 'Todos')) = 'todos'
                OR LOWER(m.estado) = LOWER(p_estado_movimiento)
              )
    ),
    movimientos_unificados AS (
        SELECT
            m.nro_referencia,
            m.fecha,
            m.estado,
            m.id_canal,
            m.id_tipo_mov,
            m.id_banco_origen,
            m.id_banco_destino,
            m.descripcion_mov,
            m.monto_comision,
            m.nro_cuenta_origen AS nro_cuenta,
            'egreso'::text AS direccion,
            m.monto_egreso AS egreso,
            0.00::numeric AS ingreso,
            m.saldo_origen_previo AS saldo_previo,
            m.saldo_origen_nuevo AS saldo_nuevo
        FROM movimientos_filtrados m

        UNION ALL

        SELECT
            m.nro_referencia,
            m.fecha,
            m.estado,
            m.id_canal,
            m.id_tipo_mov,
            m.id_banco_origen,
            m.id_banco_destino,
            m.descripcion_mov,
            0.00::numeric AS monto_comision,
            m.nro_cuenta_destino AS nro_cuenta,
            'ingreso'::text AS direccion,
            0.00::numeric AS egreso,
            m.monto_ingreso AS ingreso,
            m.saldo_destino_previo AS saldo_previo,
            m.saldo_destino_nuevo AS saldo_nuevo
        FROM movimientos_filtrados m
    )
    SELECT
        mu.nro_referencia AS "Referencia",
        mu.fecha AS "Fecha_Movimiento",
        mu.estado AS "Estado_Movimiento",
        mu.direccion AS "Direccion",
        mu.nro_cuenta AS "Cuenta",
        cu.id_cliente AS "ID",
        COALESCE(cn.primer_nombre || ' ' || cn.apellido, cj.nombre_org, 'SIN TITULAR') AS "Titular",
        c.estado AS "Estado_Cliente",
        COALESCE(cc.nro_cuentas_activas, 0) AS "Nro_Cuentas_Activas",
        COALESCE(tc.nro_tarjetas_activas, 0) AS "Nro_Tarjetas_Activas",
        cu.tipo_cuenta AS "Tipo_Cuenta",
        cu.estado AS "Estado_Cuenta",
        can_tx.tipo_canal AS "Canal_Tx",
        can_onb.descripcion AS "Canal_Descripcion",
        COALESCE(ob.nro_onboardings, 0) AS "Onboardings_Canal",
        COALESCE(pos.nro_tarjeta, ecom.nro_tarjeta, atm.nro_tarjeta, 'N/A') AS "Tarjeta",
        COALESCE(t.tipo_tarjeta, 'N/A') AS "Tipo_Tarjeta",
        COALESCE(t.estado, 'N/A') AS "Estado_Tarjeta",
        COALESCE(marca.nombre_marca, 'N/A') AS "Marca_Tarjeta",
        tm.descripcion AS "Tipo_Movimiento",
        mu.ingreso AS "Ingreso",
        mu.egreso AS "Egreso",
        mu.monto_comision AS "Comision",
        (mu.ingreso - mu.egreso) AS "Neto",
        totales.total_clientes_activos AS "Total_Clientes_Activos_BBDD",
        totales.total_cuentas_activas AS "Total_Cuentas_Activas_BBDD",
        totales.total_tarjetas_activas AS "Total_Tarjetas_Activas_BBDD",
        mu.saldo_previo AS "Saldo_Previo",
        mu.saldo_nuevo AS "Saldo_Nuevo",
        banco_origen.nombre_banco AS "Banco_Origen",
        banco_destino.nombre_banco AS "Banco_Destino",
        mu.descripcion_mov AS "Descripcion_Movimiento"
    FROM movimientos_unificados mu
    JOIN "usb_bank"."CUENTA" cu ON mu.nro_cuenta = cu.nro_cuenta
    JOIN "usb_bank"."CLIENTE" c ON cu.id_cliente = c.id_cliente
    LEFT JOIN "usb_bank"."CLIENTE_NATURAL" cn ON c.id_cliente = cn.id_cliente
    LEFT JOIN "usb_bank"."CLIENTE_JURIDICO" cj ON c.id_cliente = cj.id_cliente
    LEFT JOIN (
        SELECT id_cliente, COUNT(DISTINCT nro_cuenta) AS nro_cuentas_activas
        FROM "usb_bank"."CUENTA"
        WHERE LOWER(estado) = 'activa'
        GROUP BY id_cliente
    ) cc ON cu.id_cliente = cc.id_cliente
    LEFT JOIN (
        SELECT cu2.id_cliente, COUNT(DISTINCT t2.nro_tarjeta) AS nro_tarjetas_activas
        FROM "usb_bank"."CUENTA" cu2
        LEFT JOIN "usb_bank"."TARJETA" t2
          ON cu2.nro_cuenta = t2.nro_cuenta
         AND LOWER(t2.estado) = 'activa'
        GROUP BY cu2.id_cliente
    ) tc ON cu.id_cliente = tc.id_cliente
    LEFT JOIN (
        SELECT id_canal_onboarding AS id_canal, COUNT(*) AS nro_onboardings
        FROM "usb_bank"."CLIENTE"
        WHERE LOWER(estado) = 'activo'
        GROUP BY id_canal_onboarding
    ) ob ON c.id_canal_onboarding = ob.id_canal
    CROSS JOIN (
        SELECT
            COUNT(*) FILTER (WHERE LOWER(c3.estado) = 'activo') AS total_clientes_activos,
            (SELECT COUNT(*) FROM "usb_bank"."CUENTA" cu3 WHERE LOWER(cu3.estado) = 'activa') AS total_cuentas_activas,
            (SELECT COUNT(*) FROM "usb_bank"."TARJETA" t3 WHERE LOWER(t3.estado) = 'activa') AS total_tarjetas_activas
        FROM "usb_bank"."CLIENTE" c3
    ) totales
    JOIN "usb_bank"."CANAL" can_tx ON mu.id_canal = can_tx.id_canal
    JOIN "usb_bank"."CANAL" can_onb ON c.id_canal_onboarding = can_onb.id_canal
    JOIN "usb_bank"."TIPO_MOVIMIENTO" tm ON mu.id_tipo_mov = tm.id_tipo_mov
    JOIN "usb_bank"."BANCO" banco_origen ON mu.id_banco_origen = banco_origen.id_banco
    JOIN "usb_bank"."BANCO" banco_destino ON mu.id_banco_destino = banco_destino.id_banco
    LEFT JOIN "usb_bank"."MOVIMIENTO_PAGO_POS" pos ON mu.nro_referencia = pos.nro_referencia
    LEFT JOIN "usb_bank"."MOVIMIENTO_PAGO_ECOMMERCE" ecom ON mu.nro_referencia = ecom.nro_referencia
    LEFT JOIN "usb_bank"."MOVIMIENTO_RETIRO_ATM" atm ON mu.nro_referencia = atm.nro_referencia
    LEFT JOIN "usb_bank"."TARJETA" t ON t.nro_tarjeta = COALESCE(pos.nro_tarjeta, ecom.nro_tarjeta, atm.nro_tarjeta)
    LEFT JOIN "usb_bank"."MARCA" marca ON t.id_marca = marca.id_marca
    WHERE (mu.ingreso + mu.egreso) > 0
    ORDER BY mu.fecha DESC, cu.id_cliente;
$$;


-- Reporte contable agrupado por cliente.
CREATE OR REPLACE FUNCTION "usb_bank"."fn_reporte_contable_cliente"(
    p_fecha_inicio DATE DEFAULT NULL,
    p_fecha_fin DATE DEFAULT NULL,
    p_estado_movimiento TEXT DEFAULT 'Todos'
)
RETURNS TABLE (
    "ID" INTEGER,
    "Titular" TEXT,
    "Estado" VARCHAR(20),
    "Nro_Cuentas_Activas" BIGINT,
    "Nro_Tarjetas_Activas" BIGINT,
    "Ingresos" NUMERIC,
    "Egresos" NUMERIC,
    "Neto" NUMERIC,
    "Comisiones" NUMERIC,
    "Nro Movimientos" BIGINT,
    "Total_Clientes_Activos_BBDD" BIGINT,
    "Mov Transferencia" NUMERIC,
    "Mov_Pago_Ecommerce" NUMERIC,
    "Mov_Pago_POS" NUMERIC,
    "Mov_Retiro_ATM" NUMERIC,
    "Mov_Pago_Movil" NUMERIC
)
LANGUAGE SQL
STABLE
AS $$
    SELECT
        b.id_cliente AS "ID",
        MAX(b.titular) AS "Titular",
        MAX(b.estado_cliente) AS "Estado",
        MAX(b.nro_cuentas_activas) AS "Nro_Cuentas_Activas",
        MAX(b.nro_tarjetas_activas) AS "Nro_Tarjetas_Activas",
        SUM(b.ingreso) AS "Ingresos",
        SUM(b.egreso) AS "Egresos",
        SUM(b.neto) AS "Neto",
        SUM(b.comision) AS "Comisiones",
        COUNT(DISTINCT b.referencia) AS "Nro Movimientos",
        MAX(b.total_clientes_activos_bbdd) AS "Total_Clientes_Activos_BBDD",
        SUM(CASE WHEN LOWER(b.tipo_movimiento) IN ('transferencia interbancaria', 'transferencia entre cuentas') THEN b.monto_movido ELSE 0 END) AS "Mov Transferencia",
        SUM(CASE WHEN LOWER(b.tipo_movimiento) = 'pago por ecommerce' THEN b.monto_movido ELSE 0 END) AS "Mov_Pago_Ecommerce",
        SUM(CASE WHEN LOWER(b.tipo_movimiento) = 'pago por punto de venta' THEN b.monto_movido ELSE 0 END) AS "Mov_Pago_POS",
        SUM(CASE WHEN LOWER(b.tipo_movimiento) = 'retiro en cajero automatico' THEN b.monto_movido ELSE 0 END) AS "Mov_Retiro_ATM",
        SUM(CASE WHEN LOWER(b.tipo_movimiento) = 'pago movil' THEN b.monto_movido ELSE 0 END) AS "Mov_Pago_Movil"
    FROM "usb_bank"."fn_reporte_contable_base"(p_fecha_inicio, p_fecha_fin, p_estado_movimiento) b
    GROUP BY b.id_cliente
    ORDER BY "Neto" DESC;
$$;


-- Reporte contable agrupado por cuenta.
CREATE OR REPLACE FUNCTION "usb_bank"."fn_reporte_contable_cuenta"(
    p_fecha_inicio DATE DEFAULT NULL,
    p_fecha_fin DATE DEFAULT NULL,
    p_estado_movimiento TEXT DEFAULT 'Todos'
)
RETURNS TABLE (
    "Nro_Cuenta" VARCHAR(20),
    "Titular" TEXT,
    "Estado" VARCHAR(20),
    "Ingresos" NUMERIC,
    "Egresos" NUMERIC,
    "Neto" NUMERIC,
    "Comisiones" NUMERIC,
    "Nro Movimientos" BIGINT,
    "Total_Cuentas_Activas_BBDD" BIGINT,
    "Mov Transferencia" NUMERIC,
    "Mov_Pago_Ecommerce" NUMERIC,
    "Mov_Pago_POS" NUMERIC,
    "Mov_Retiro_ATM" NUMERIC,
    "Mov_Pago_Movil" NUMERIC
)
LANGUAGE SQL
STABLE
AS $$
    SELECT
        b.nro_cuenta AS "Nro_Cuenta",
        MAX(b.titular) AS "Titular",
        MAX(b.estado_cuenta) AS "Estado",
        SUM(b.ingreso) AS "Ingresos",
        SUM(b.egreso) AS "Egresos",
        SUM(b.neto) AS "Neto",
        SUM(b.comision) AS "Comisiones",
        COUNT(DISTINCT b.referencia) AS "Nro Movimientos",
        MAX(b.total_cuentas_activas_bbdd) AS "Total_Cuentas_Activas_BBDD",
        SUM(CASE WHEN LOWER(b.tipo_movimiento) IN ('transferencia interbancaria', 'transferencia entre cuentas') THEN b.monto_movido ELSE 0 END) AS "Mov Transferencia",
        SUM(CASE WHEN LOWER(b.tipo_movimiento) = 'pago por ecommerce' THEN b.monto_movido ELSE 0 END) AS "Mov_Pago_Ecommerce",
        SUM(CASE WHEN LOWER(b.tipo_movimiento) = 'pago por punto de venta' THEN b.monto_movido ELSE 0 END) AS "Mov_Pago_POS",
        SUM(CASE WHEN LOWER(b.tipo_movimiento) = 'retiro en cajero automatico' THEN b.monto_movido ELSE 0 END) AS "Mov_Retiro_ATM",
        SUM(CASE WHEN LOWER(b.tipo_movimiento) = 'pago movil' THEN b.monto_movido ELSE 0 END) AS "Mov_Pago_Movil"
    FROM "usb_bank"."fn_reporte_contable_base"(p_fecha_inicio, p_fecha_fin, p_estado_movimiento) b
    GROUP BY b.nro_cuenta
    ORDER BY "Neto" DESC;
$$;


-- Reporte contable agrupado por canal.
CREATE OR REPLACE FUNCTION "usb_bank"."fn_reporte_contable_canal"(
    p_fecha_inicio DATE DEFAULT NULL,
    p_fecha_fin DATE DEFAULT NULL,
    p_estado_movimiento TEXT DEFAULT 'Todos'
)
RETURNS TABLE (
    "Canal_Descripcion" VARCHAR(100),
    "Onboardings_Canal" BIGINT,
    "Ingresos" NUMERIC,
    "Egresos" NUMERIC,
    "Neto" NUMERIC,
    "Comisiones" NUMERIC,
    "Nro Movimientos" BIGINT
)
LANGUAGE SQL
STABLE
AS $$
    SELECT
        b.canal_descripcion AS "Canal_Descripcion",
        MAX(b.onboardings_canal) AS "Onboardings_Canal",
        SUM(b.ingreso) AS "Ingresos",
        SUM(b.egreso) AS "Egresos",
        SUM(b.neto) AS "Neto",
        SUM(b.comision) AS "Comisiones",
        COUNT(DISTINCT b.referencia) AS "Nro Movimientos"
    FROM "usb_bank"."fn_reporte_contable_base"(p_fecha_inicio, p_fecha_fin, p_estado_movimiento) b
    GROUP BY b.canal_descripcion
    ORDER BY "Nro Movimientos" DESC;
$$;


-- Reporte contable agrupado por tarjeta.
CREATE OR REPLACE FUNCTION "usb_bank"."fn_reporte_contable_tarjeta"(
    p_fecha_inicio DATE DEFAULT NULL,
    p_fecha_fin DATE DEFAULT NULL,
    p_estado_movimiento TEXT DEFAULT 'Todos'
)
RETURNS TABLE (
    "Nro_Tarjeta" VARCHAR(16),
    "Titular" TEXT,
    "Tipo_Tarjeta" VARCHAR(20),
    "Estado" VARCHAR(20),
    "Ingresos" NUMERIC,
    "Egresos" NUMERIC,
    "Neto" NUMERIC,
    "Comisiones" NUMERIC,
    "Nro Movimientos" BIGINT,
    "Total_Tarjetas_Activas_BBDD" BIGINT,
    "Mov_Pago_Ecommerce" NUMERIC,
    "Mov_Pago_POS" NUMERIC,
    "Mov_Retiro_ATM" NUMERIC
)
LANGUAGE SQL
STABLE
AS $$
    SELECT
                b.nro_tarjeta AS "Nro_Tarjeta",
                MAX(b.titular) AS "Titular",
                MAX(b.tipo_tarjeta) AS "Tipo_Tarjeta",
                MAX(b.estado_tarjeta) AS "Estado",
                SUM(b.ingreso) AS "Ingresos",
                SUM(b.egreso) AS "Egresos",
                SUM(b.neto) AS "Neto",
                SUM(b.comision) AS "Comisiones",
                COUNT(DISTINCT b.referencia) AS "Nro Movimientos",
                MAX(b.total_tarjetas_activas_bbdd) AS "Total_Tarjetas_Activas_BBDD",
                SUM(CASE WHEN LOWER(b.tipo_movimiento) = 'pago por ecommerce' THEN b.monto_movido ELSE 0 END) AS "Mov_Pago_Ecommerce",
                SUM(CASE WHEN LOWER(b.tipo_movimiento) = 'pago por punto de venta' THEN b.monto_movido ELSE 0 END) AS "Mov_Pago_POS",
                SUM(CASE WHEN LOWER(b.tipo_movimiento) = 'retiro en cajero automatico' THEN b.monto_movido ELSE 0 END) AS "Mov_Retiro_ATM"
    FROM "usb_bank"."fn_reporte_contable_base"(p_fecha_inicio, p_fecha_fin, p_estado_movimiento) b
    WHERE b.nro_tarjeta IS NOT NULL
      AND b.nro_tarjeta <> 'N/A'
    GROUP BY b.nro_tarjeta
        ORDER BY "Neto" DESC;
$$;

-- Ejemplos de uso rapido en terminal psql:
-- SELECT * FROM "usb_bank"."fn_reporte_contable_cliente"(NULL, NULL, 'Todos');
-- SELECT * FROM "usb_bank"."fn_reporte_contable_cuenta"('2026-01-01', '2026-12-31', 'Todos');
-- SELECT * FROM "usb_bank"."fn_reporte_contable_canal"(NULL, NULL, 'Todos');
-- SELECT * FROM "usb_bank"."fn_reporte_contable_tarjeta"(NULL, NULL, 'Todos');

