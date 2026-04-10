-- ==============================================================================
-- FUNCIÓN: REPORTE ESTADÍSTICO CBO (Cumplimiento NIIF y KPIs)
-- Autor: Brian Orta (Corregido)
-- ==============================================================================

SET search_path TO "USB_Bank_Schema";

CREATE OR REPLACE FUNCTION fn_reporte_estadistico()
RETURNS TABLE (
    "ID_Cliente" INTEGER,
    "Nombre_Completo" VARCHAR,
    "Tipo" VARCHAR,
    "Canal" VARCHAR,
    "Total_Cuentas" BIGINT,
    "Total_Tarjetas" BIGINT,
    "Activos_Debe" NUMERIC,
    "Pasivos_Haber" NUMERIC,
    "Fecha_Registro" TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id_cliente,
        -- Sin iniciales, concatenación limpia o Razón Social
        COALESCE(cn.primer_nombre || ' ' || cn.apellido, cj.nombre_org)::VARCHAR AS "Nombre_Completo",
        
        -- Set de Valor: N (Natural) o J (Jurídico)
        CASE WHEN tc.descripcion = 'Natural' THEN 'N' ELSE 'J' END::VARCHAR AS "Tipo",
        
        -- Set de Valor Canales: W(Web), M(Móvil), A(ATM), P(POS), I(IVR)
        CASE 
            WHEN can.descripcion ILIKE '%Web%' THEN 'W'
            WHEN can.descripcion ILIKE '%Movil%' THEN 'M'
            WHEN can.descripcion ILIKE '%ATM%' THEN 'A'
            WHEN can.descripcion ILIKE '%POS%' THEN 'P'
            WHEN can.descripcion ILIKE '%IVR%' THEN 'I'
            ELSE 'O'
        END::VARCHAR AS "Canal",
        
        -- Subtotales de Productos aislados (Cero Producto Cartesiano)
        COALESCE(cu_agg.total_cuentas, 0)::BIGINT AS "Total_Cuentas",
        COALESCE(t_agg.total_tarjetas, 0)::BIGINT AS "Total_Tarjetas",
        
        -- Subdivisión Contable (Debe = Activos/Saldo a favor, Haber = Pasivos/Deuda TDC)
        COALESCE(cu_agg.activos_debe, 0.00)::NUMERIC AS "Activos_Debe",
        COALESCE(t_agg.pasivos_haber, 0.00)::NUMERIC AS "Pasivos_Haber",
        
        c.fecha_registro
    FROM "CLIENTE" c
    JOIN "TIPO_CLIENTE" tc ON c.tipo_cliente = tc.id_tipo_cliente
    LEFT JOIN "CLIENTE_NATURAL" cn ON c.id_cliente = cn.id_cliente
    LEFT JOIN "CLIENTE_JURIDICO" cj ON c.id_cliente = cj.id_cliente
    JOIN "CANAL" can ON c.id_canal_onboarding = can.id_canal
    
    -- Subconsulta A: Activos (Debe) y Cuentas
    LEFT JOIN (
        SELECT id_cliente, COUNT(nro_cuenta) AS total_cuentas, SUM(saldo) AS activos_debe
        FROM "CUENTA" 
        WHERE estado = 'activa'
        GROUP BY id_cliente
    ) cu_agg ON c.id_cliente = cu_agg.id_cliente
    
    -- Subconsulta B: Pasivos (Haber) y Tarjetas
    LEFT JOIN (
        SELECT cu.id_cliente, COUNT(t.nro_tarjeta) AS total_tarjetas, SUM(tc.saldo_consumido) AS pasivos_haber
        FROM "CUENTA" cu
        JOIN "TARJETA" t ON cu.nro_cuenta = t.nro_cuenta
        LEFT JOIN "TARJETA_CREDITO" tc ON t.nro_tarjeta = tc.nro_tarjeta
        WHERE t.estado = 'activa'
        GROUP BY cu.id_cliente
    ) t_agg ON c.id_cliente = t_agg.id_cliente
    ORDER BY c.id_cliente;
END;
$$ LANGUAGE plpgsql;