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
    nro_cuentas_cliente BIGINT,
    nro_tarjetas_cliente BIGINT,
    tipo_cuenta VARCHAR(20),
    canal_descripcion VARCHAR(100),
    nro_tarjeta VARCHAR(16),
    tipo_tarjeta VARCHAR(20),
    tipo_movimiento VARCHAR(100),
    ingreso NUMERIC,
    egreso NUMERIC,
    comision NUMERIC,
    neto NUMERIC,
    monto_movido NUMERIC
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
        COALESCE(cc.nro_cuentas_cliente, 0) AS nro_cuentas_cliente,
        COALESCE(tc.nro_tarjetas_cliente, 0) AS nro_tarjetas_cliente,
        cu.tipo_cuenta,
        can.descripcion AS canal_descripcion,
        COALESCE(pos.nro_tarjeta, ecom.nro_tarjeta, atm.nro_tarjeta, 'N/A') AS nro_tarjeta,
        COALESCE(t.tipo_tarjeta, 'N/A') AS tipo_tarjeta,
        tm.descripcion AS tipo_movimiento,
        mu.ingreso,
        mu.egreso,
        mu.monto_comision AS comision,
        (mu.ingreso - mu.egreso) AS neto,
        (mu.ingreso + mu.egreso) AS monto_movido
    FROM movimientos_unificados mu
    JOIN "usb_bank"."CUENTA" cu ON mu.nro_cuenta = cu.nro_cuenta
    JOIN "usb_bank"."CLIENTE" c ON cu.id_cliente = c.id_cliente
    LEFT JOIN "usb_bank"."CLIENTE_NATURAL" cn ON c.id_cliente = cn.id_cliente
    LEFT JOIN "usb_bank"."CLIENTE_JURIDICO" cj ON c.id_cliente = cj.id_cliente
    LEFT JOIN (
        SELECT id_cliente, COUNT(DISTINCT nro_cuenta) AS nro_cuentas_cliente
        FROM "usb_bank"."CUENTA"
        GROUP BY id_cliente
    ) cc ON cu.id_cliente = cc.id_cliente
    LEFT JOIN (
        SELECT cu2.id_cliente, COUNT(DISTINCT t2.nro_tarjeta) AS nro_tarjetas_cliente
        FROM "usb_bank"."CUENTA" cu2
        LEFT JOIN "usb_bank"."TARJETA" t2 ON cu2.nro_cuenta = t2.nro_cuenta
        GROUP BY cu2.id_cliente
    ) tc ON cu.id_cliente = tc.id_cliente
    JOIN "usb_bank"."CANAL" can ON mu.id_canal = can.id_canal
    JOIN "usb_bank"."TIPO_MOVIMIENTO" tm ON mu.id_tipo_mov = tm.id_tipo_mov
    LEFT JOIN "usb_bank"."MOVIMIENTO_PAGO_POS" pos ON mu.nro_referencia = pos.nro_referencia
    LEFT JOIN "usb_bank"."MOVIMIENTO_PAGO_ECOMMERCE" ecom ON mu.nro_referencia = ecom.nro_referencia
    LEFT JOIN "usb_bank"."MOVIMIENTO_RETIRO_ATM" atm ON mu.nro_referencia = atm.nro_referencia
    LEFT JOIN "usb_bank"."TARJETA" t ON t.nro_tarjeta = COALESCE(pos.nro_tarjeta, ecom.nro_tarjeta, atm.nro_tarjeta)
    WHERE (mu.ingreso + mu.egreso) > 0;
$$;


-- Reporte contable agrupado por cliente.
CREATE OR REPLACE FUNCTION "usb_bank"."fn_reporte_contable_cliente"(
    p_fecha_inicio DATE DEFAULT NULL,
    p_fecha_fin DATE DEFAULT NULL,
    p_estado_movimiento TEXT DEFAULT 'Todos'
)
RETURNS TABLE (
    id_cliente INTEGER,
    titular TEXT,
    nro_cuentas_cliente BIGINT,
    nro_tarjetas_cliente BIGINT,
    ingresos NUMERIC,
    egresos NUMERIC,
    neto NUMERIC,
    comisiones NUMERIC,
    nro_movimientos BIGINT,
    mov_transferencia_interbancaria NUMERIC,
    mov_pago_ecommerce NUMERIC,
    mov_pago_pos NUMERIC,
    mov_retiro_atm NUMERIC,
    mov_pago_movil NUMERIC
)
LANGUAGE SQL
STABLE
AS $$
    SELECT
        b.id_cliente,
        MAX(b.titular) AS titular,
        MAX(b.nro_cuentas_cliente) AS nro_cuentas_cliente,
        MAX(b.nro_tarjetas_cliente) AS nro_tarjetas_cliente,
        SUM(b.ingreso) AS ingresos,
        SUM(b.egreso) AS egresos,
        SUM(b.neto) AS neto,
        SUM(b.comision) AS comisiones,
        COUNT(DISTINCT b.referencia) AS nro_movimientos,
        SUM(CASE WHEN LOWER(b.tipo_movimiento) IN ('transferencia interbancaria', 'transferencia entre cuentas') THEN b.monto_movido ELSE 0 END) AS mov_transferencia_interbancaria,
        SUM(CASE WHEN LOWER(b.tipo_movimiento) = 'pago por ecommerce' THEN b.monto_movido ELSE 0 END) AS mov_pago_ecommerce,
        SUM(CASE WHEN LOWER(b.tipo_movimiento) = 'pago por punto de venta' THEN b.monto_movido ELSE 0 END) AS mov_pago_pos,
        SUM(CASE WHEN LOWER(b.tipo_movimiento) = 'retiro en cajero automatico' THEN b.monto_movido ELSE 0 END) AS mov_retiro_atm,
        SUM(CASE WHEN LOWER(b.tipo_movimiento) = 'pago movil' THEN b.monto_movido ELSE 0 END) AS mov_pago_movil
    FROM "usb_bank"."fn_reporte_contable_base"(p_fecha_inicio, p_fecha_fin, p_estado_movimiento) b
    GROUP BY b.id_cliente
    ORDER BY neto DESC;
$$;


-- Reporte contable agrupado por cuenta.
CREATE OR REPLACE FUNCTION "usb_bank"."fn_reporte_contable_cuenta"(
    p_fecha_inicio DATE DEFAULT NULL,
    p_fecha_fin DATE DEFAULT NULL,
    p_estado_movimiento TEXT DEFAULT 'Todos'
)
RETURNS TABLE (
    nro_cuenta VARCHAR(20),
    titular TEXT,
    ingresos NUMERIC,
    egresos NUMERIC,
    neto NUMERIC,
    comisiones NUMERIC,
    nro_movimientos BIGINT,
    mov_transferencia_interbancaria NUMERIC,
    mov_pago_ecommerce NUMERIC,
    mov_pago_pos NUMERIC,
    mov_retiro_atm NUMERIC,
    mov_pago_movil NUMERIC
)
LANGUAGE SQL
STABLE
AS $$
    SELECT
        b.nro_cuenta,
        MAX(b.titular) AS titular,
        SUM(b.ingreso) AS ingresos,
        SUM(b.egreso) AS egresos,
        SUM(b.neto) AS neto,
        SUM(b.comision) AS comisiones,
        COUNT(DISTINCT b.referencia) AS nro_movimientos,
        SUM(CASE WHEN LOWER(b.tipo_movimiento) IN ('transferencia interbancaria', 'transferencia entre cuentas') THEN b.monto_movido ELSE 0 END) AS mov_transferencia_interbancaria,
        SUM(CASE WHEN LOWER(b.tipo_movimiento) = 'pago por ecommerce' THEN b.monto_movido ELSE 0 END) AS mov_pago_ecommerce,
        SUM(CASE WHEN LOWER(b.tipo_movimiento) = 'pago por punto de venta' THEN b.monto_movido ELSE 0 END) AS mov_pago_pos,
        SUM(CASE WHEN LOWER(b.tipo_movimiento) = 'retiro en cajero automatico' THEN b.monto_movido ELSE 0 END) AS mov_retiro_atm,
        SUM(CASE WHEN LOWER(b.tipo_movimiento) = 'pago movil' THEN b.monto_movido ELSE 0 END) AS mov_pago_movil
    FROM "usb_bank"."fn_reporte_contable_base"(p_fecha_inicio, p_fecha_fin, p_estado_movimiento) b
    GROUP BY b.nro_cuenta
    ORDER BY neto DESC;
$$;


-- Reporte contable agrupado por canal.
CREATE OR REPLACE FUNCTION "usb_bank"."fn_reporte_contable_canal"(
    p_fecha_inicio DATE DEFAULT NULL,
    p_fecha_fin DATE DEFAULT NULL,
    p_estado_movimiento TEXT DEFAULT 'Todos'
)
RETURNS TABLE (
    canal_descripcion VARCHAR(100),
    ingresos NUMERIC,
    egresos NUMERIC,
    neto NUMERIC,
    comisiones NUMERIC,
    nro_movimientos BIGINT
)
LANGUAGE SQL
STABLE
AS $$
    SELECT
        b.canal_descripcion,
        SUM(b.ingreso) AS ingresos,
        SUM(b.egreso) AS egresos,
        SUM(b.neto) AS neto,
        SUM(b.comision) AS comisiones,
        COUNT(DISTINCT b.referencia) AS nro_movimientos
    FROM "usb_bank"."fn_reporte_contable_base"(p_fecha_inicio, p_fecha_fin, p_estado_movimiento) b
    GROUP BY b.canal_descripcion
    ORDER BY nro_movimientos DESC;
$$;


-- Reporte contable agrupado por tarjeta.
CREATE OR REPLACE FUNCTION "usb_bank"."fn_reporte_contable_tarjeta"(
    p_fecha_inicio DATE DEFAULT NULL,
    p_fecha_fin DATE DEFAULT NULL,
    p_estado_movimiento TEXT DEFAULT 'Todos'
)
RETURNS TABLE (
    nro_tarjeta VARCHAR(16),
    titular TEXT,
    tipo_tarjeta VARCHAR(20),
    ingresos NUMERIC,
    egresos NUMERIC,
    neto NUMERIC,
    comisiones NUMERIC,
    nro_movimientos BIGINT,
    mov_pago_ecommerce NUMERIC,
    mov_pago_pos NUMERIC,
    mov_retiro_atm NUMERIC
)
LANGUAGE SQL
STABLE
AS $$
    SELECT
        b.nro_tarjeta,
        MAX(b.titular) AS titular,
        MAX(b.tipo_tarjeta) AS tipo_tarjeta,
        SUM(b.ingreso) AS ingresos,
        SUM(b.egreso) AS egresos,
        SUM(b.neto) AS neto,
        SUM(b.comision) AS comisiones,
        COUNT(DISTINCT b.referencia) AS nro_movimientos,
        SUM(CASE WHEN LOWER(b.tipo_movimiento) = 'pago por ecommerce' THEN b.monto_movido ELSE 0 END) AS mov_pago_ecommerce,
        SUM(CASE WHEN LOWER(b.tipo_movimiento) = 'pago por punto de venta' THEN b.monto_movido ELSE 0 END) AS mov_pago_pos,
        SUM(CASE WHEN LOWER(b.tipo_movimiento) = 'retiro en cajero automatico' THEN b.monto_movido ELSE 0 END) AS mov_retiro_atm
    FROM "usb_bank"."fn_reporte_contable_base"(p_fecha_inicio, p_fecha_fin, p_estado_movimiento) b
    WHERE b.nro_tarjeta IS NOT NULL
      AND b.nro_tarjeta <> 'N/A'
    GROUP BY b.nro_tarjeta
    ORDER BY neto DESC;
$$;

-- Ejemplos de uso rapido en terminal psql:
-- SELECT * FROM "usb_bank"."fn_reporte_contable_cliente"(NULL, NULL, 'Todos');
-- SELECT * FROM "usb_bank"."fn_reporte_contable_cuenta"('2026-01-01', '2026-12-31', 'Todos');
-- SELECT * FROM "usb_bank"."fn_reporte_contable_canal"(NULL, NULL, 'Todos');
-- SELECT * FROM "usb_bank"."fn_reporte_contable_tarjeta"(NULL, NULL, 'Todos');
