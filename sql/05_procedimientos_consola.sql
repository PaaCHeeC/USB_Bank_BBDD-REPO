SET search_path TO "usb_bank";

--Reportes: 
--Este procedimiento imprime por consola las 9 columnas: referencia, fecha, tipo, nro de cuenta, titular, movimiento, ingreso, egreso y neto
--lo que 'retorna' este procedmiento es una serie de strings que dan el formato de tabla al reporte en cuestion
CREATE OR REPLACE PROCEDURE "usb_bank"."sp_imprimir_reporte_estadistico"()
LANGUAGE plpgsql
AS $$
DECLARE
    registro RECORD;
    -- Definimos los anchos de columna para que se vean de manera correcta en pantalla 
    ancho_id     CONSTANT INT := 6;
    ancho_nom    CONSTANT INT := 30;
    ancho_tipo   CONSTANT INT := 15;
    ancho_canal  CONSTANT INT := 12;
    ancho_saldo  CONSTANT INT := 15;
    ancho_fecha  CONSTANT INT := 22;
    ancho_cant   CONSTANT INT := 8;
    
    linea_separadora TEXT;
BEGIN
    -- Crea una línea visual para el encabezado del reporte
    linea_separadora := REPEAT('-', ancho_id + ancho_nom + ancho_tipo + ancho_canal + ancho_saldo + ancho_fecha + ancho_cant + 14);

    -- imprime el encabezado del reporte 
    RAISE NOTICE '%', linea_separadora;
    RAISE NOTICE '| % | % | % | % | % | % | % |', 
        RPAD('ID', ancho_id), 
        RPAD('TITULAR', ancho_nom), 
        RPAD('TIPO CLIENTE', ancho_tipo),
        RPAD('CANAL', ancho_canal),
        LPAD('SALDO TOTAL', ancho_saldo),
        RPAD('FECHA REGISTRO', ancho_fecha),
        LPAD('CUENTAS', ancho_cant);
    RAISE NOTICE '%', linea_separadora;

    -- Bucle que se usa para recorrer los resultados de la función resumen_estadistico()
    FOR registro IN (SELECT * FROM "usb_bank"."resumen_estadistico"()) LOOP
        RAISE NOTICE '| % | % | % | % | % | % | % |', 

            RPAD(registro.ids::TEXT, ancho_id), 
            RPAD(SUBSTRING(registro.nombre_cliente, 1, ancho_nom), ancho_nom), 
            RPAD(registro.tipo_cliente, ancho_tipo),
            RPAD(registro.canal, ancho_canal),
            LPAD(TO_CHAR(registro.saldo_total, 'FM999,999,990.00'), ancho_saldo),
            RPAD(TO_CHAR(registro.fecha, 'YYYY-MM-DD HH24:MI:SS'), ancho_fecha),
            LPAD(registro.cuenta::TEXT, ancho_cant);
    END LOOP;

    RAISE NOTICE '%', linea_separadora;
END;
$$;

CREATE OR REPLACE PROCEDURE "usb_bank"."sp_imprimir_reporte_contable"(
    p_fecha_inicio DATE DEFAULT NULL,
    p_fecha_fin DATE DEFAULT NULL,
    p_estado TEXT DEFAULT 'Todos'
)
LANGUAGE plpgsql
AS $$
DECLARE
    registro RECORD;
    -- Definimos los anchos de columna (ajustados para que quepan en una pantalla típica, pq sino no se ven)
    w_ref CONSTANT INT := 14;
    w_fec CONSTANT INT := 19;
    w_dir CONSTANT INT := 8;
    w_cta CONSTANT INT := 16;
    w_tit CONSTANT INT := 22;
    w_mov CONSTANT INT := 14;
    w_ing CONSTANT INT := 12;
    w_egr CONSTANT INT := 12;
    w_net CONSTANT INT := 13;
    
    linea_separadora TEXT;
BEGIN
    -- Crea una línea separadora calculando el ancho total más los bordes y separadores (|)
    linea_separadora := REPEAT('-', w_ref + w_fec + w_dir + w_cta + w_tit + w_mov + w_ing + w_egr + w_net + 26);

    -- aqui se imprime el encabezado del reporte 
    RAISE NOTICE '%', linea_separadora;
    RAISE NOTICE '| % | % | % | % | % | % | % | % | % |', 
        RPAD('REFERENCIA', w_ref),
        RPAD('FECHA', w_fec),
        RPAD('TIPO', w_dir),
        RPAD('NRO CUENTA', w_cta),
        RPAD('TITULAR', w_tit),
        RPAD('MOVIMIENTO', w_mov),
        LPAD('INGRESO', w_ing),
        LPAD('EGRESO', w_egr),
        LPAD('NETO', w_net);
    RAISE NOTICE '%', linea_separadora;

    -- este bucle recorre los resultados de la funcion 
    -- Le pasamos los parámetros del procedmiento directamente a la función
    FOR registro IN (SELECT * FROM "usb_bank"."fn_reporte_contable_base"(p_fecha_inicio, p_fecha_fin, p_estado)) LOOP
        RAISE NOTICE '| % | % | % | % | % | % | % | % | % |', 
            RPAD(COALESCE(SUBSTRING(registro.referencia, 1, w_ref), ''), w_ref),
            RPAD(TO_CHAR(registro.fecha_movimiento, 'YYYY-MM-DD HH24:MI:SS'), w_fec),
            RPAD(UPPER(COALESCE(registro.direccion, '')), w_dir), -- Mayúsculas para ingreso/egreso
            RPAD(COALESCE(registro.nro_cuenta, ''), w_cta),
            RPAD(COALESCE(SUBSTRING(registro.titular, 1, w_tit), ''), w_tit),
            RPAD(COALESCE(SUBSTRING(registro.tipo_movimiento, 1, w_mov), ''), w_mov),
            LPAD(TO_CHAR(COALESCE(registro.ingreso, 0), 'FM999,999,990.00'), w_ing),
            LPAD(TO_CHAR(COALESCE(registro.egreso, 0), 'FM999,999,990.00'), w_egr),
            LPAD(TO_CHAR(COALESCE(registro.neto, 0), 'FM999,999,990.00'), w_net);
    END LOOP;

    RAISE NOTICE '%', linea_separadora;
END;
$$;

--ejemplo de llamada de los procedimientos: 
--este imprime el reporte estadistico 
CALL sp_imprimir_reporte_estadistico();

--este imprime el reporte contable 
CALL sp_imprimir_reporte_contable();