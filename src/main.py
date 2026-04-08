import psycopg2
import pandas as pd
import warnings
from config import config
from generador_reportes import generador_reportes_estadisticos, generador_reportes_contables, generador_reportes_auditoria
warnings.filterwarnings('ignore', category=UserWarning)

def obtener_datos_y_generar(tipo_reporte, filtros):
    connection = None
    
    try:
        params = config()
        print('Conectando con la base de datos en PostgreSQL ...')
        connection = psycopg2.connect(**params)
        
        if tipo_reporte == 'estadistico':
            query = """
                SELECT 
                    "CLIENTE".id_cliente AS "ID_Cliente", 
                    COALESCE("CLIENTE_NATURAL".primer_nombre || ' ' || "CLIENTE_NATURAL".apellido, 
                "CLIENTE_JURIDICO".nombre_org) AS "Nombre", 
                    "CLIENTE".tipo_cliente AS "Tipo_Cliente", 
                    "CANAL".tipo_canal AS "Canal_Afiliacion",
                    COALESCE("CUENTA".cuentas, 0) AS "Total_Productos",
                    COALESCE("CUENTA".saldo_total_cuenta, 0.00) AS "Saldo_Total",
                    "CLIENTE".fecha_registro AS "Fecha_Registro"
                FROM usb_bank."CLIENTE"
                LEFT JOIN usb_bank."CLIENTE_NATURAL" ON "CLIENTE"."id_cliente" = "CLIENTE_NATURAL"."id_cliente"
                LEFT JOIN usb_bank."CLIENTE_JURIDICO" ON "CLIENTE"."id_cliente" = "CLIENTE_JURIDICO"."id_cliente"
                JOIN usb_bank."CANAL" ON "CLIENTE"."id_canal_onboarding" = "CANAL"."id_canal"
                LEFT JOIN (
                    SELECT id_cliente, 
                    SUM(saldo) AS saldo_total_cuenta, 
                    COUNT(id_cliente) AS cuentas 
                    FROM usb_bank."CUENTA"
                    GROUP BY id_cliente
                ) "CUENTA" ON "CLIENTE"."id_cliente" = "CUENTA"."id_cliente"
                ORDER BY "CLIENTE".id_cliente;
            """
        elif tipo_reporte == 'contable':
            query = """
                WITH Movimientos_Unificados AS (
                    SELECT nro_cuenta_origen AS nro_cuenta, monto_egreso AS Egreso, 0.00 AS Ingreso, nro_referencia, id_canal, id_tipo_mov
                    FROM "usb_bank"."MOVIMIENTO"
                    
                    UNION ALL
                    
                    SELECT nro_cuenta_destino AS nro_cuenta, 0.00 AS Egreso, monto_ingreso AS Ingreso, nro_referencia, id_canal, id_tipo_mov
                    FROM "usb_bank"."MOVIMIENTO"
                )
                SELECT 
                    mu.nro_cuenta AS "Cuenta",
                    cu.id_cliente AS "ID_Cliente",
                    can.tipo_canal AS "Canal_Tx",
                    COALESCE(pos.nro_tarjeta, ecom.nro_tarjeta, atm.nro_tarjeta, 'N/A') AS "Tarjeta",
                    tm.descripcion AS "Tipo_Movimiento",
                    (mu.Ingreso + mu.Egreso) AS "Monto"
                FROM Movimientos_Unificados mu
                JOIN "usb_bank"."CUENTA" cu ON mu.nro_cuenta = cu.nro_cuenta
                JOIN "usb_bank"."CANAL" can ON mu.id_canal = can.id_canal
                JOIN "usb_bank"."TIPO_MOVIMIENTO" tm ON mu.id_tipo_mov = tm.id_tipo_mov
                LEFT JOIN "usb_bank"."MOVIMIENTO_PAGO_POS" pos ON mu.nro_referencia = pos.nro_referencia
                LEFT JOIN "usb_bank"."MOVIMIENTO_PAGO_ECOMMERCE" ecom ON mu.nro_referencia = ecom.nro_referencia
                LEFT JOIN "usb_bank"."MOVIMIENTO_RETIRO_ATM" atm ON mu.nro_referencia = atm.nro_referencia
                WHERE (mu.Ingreso + mu.Egreso) > 0 
                ORDER BY cu.id_cliente;
            """
            
        elif tipo_reporte == 'auditoria':
            # --- QUERY DE AUDITORÍA Y LIMPIEZA ---
            print("Iniciando rutina de limpieza de inactivos...")
            
            # 1. Ejecutar el DELETE masivo (Esto dispara el Trigger en PostgreSQL)
            query_delete = """
                SET search_path TO "usb_bank";
                
                DELETE FROM "usb_bank"."CLIENTE" c
                WHERE c.id_cliente IN (
                    SELECT cu.id_cliente FROM "usb_bank"."CUENTA" cu 
                    JOIN "usb_bank"."TARJETA" t ON cu.nro_cuenta = t.nro_cuenta
                )
                AND c.id_cliente NOT IN (
                    SELECT cu.id_cliente FROM "usb_bank"."CUENTA" cu 
                    JOIN "usb_bank"."TARJETA" t ON cu.nro_cuenta = t.nro_cuenta 
                    JOIN "usb_bank"."MOVIMIENTO_PAGO_POS" mp ON t.nro_tarjeta = mp.nro_tarjeta 
                    JOIN "usb_bank"."MOVIMIENTO" m ON mp.nro_referencia = m.nro_referencia 
                    WHERE m.fecha >= CURRENT_DATE - INTERVAL '1 month'
                    
                    UNION
                    
                    SELECT cu.id_cliente FROM "usb_bank"."CUENTA" cu 
                    JOIN "usb_bank"."TARJETA" t ON cu.nro_cuenta = t.nro_cuenta 
                    JOIN "usb_bank"."MOVIMIENTO_PAGO_ECOMMERCE" me ON t.nro_tarjeta = me.nro_tarjeta 
                    JOIN "usb_bank"."MOVIMIENTO" m ON me.nro_referencia = m.nro_referencia 
                    WHERE m.fecha >= CURRENT_DATE - INTERVAL '1 month'
                    
                    UNION
                    
                    SELECT cu.id_cliente FROM "usb_bank"."CUENTA" cu 
                    JOIN "usb_bank"."TARJETA" t ON cu.nro_cuenta = t.nro_cuenta 
                    JOIN "usb_bank"."MOVIMIENTO_RETIRO_ATM" ma ON t.nro_tarjeta = ma.nro_tarjeta 
                    JOIN "usb_bank"."MOVIMIENTO" m ON ma.nro_referencia = m.nro_referencia 
                    WHERE m.fecha >= CURRENT_DATE - INTERVAL '1 month'
                );
            """
            cursor = connection.cursor()
            cursor.execute(query_delete)
            eliminados = cursor.rowcount
            connection.commit()
            cursor.close()
            print(f"Limpieza ejecutada. Se eliminaron {eliminados} clientes. Triggers disparados.")

            # 2. Extraer la tabla de auditoría resultante
            query = 'SELECT * FROM "usb_bank"."REPORTE_CLIENTES_ELIMINADOS" ORDER BY fecha_eliminacion DESC;'
            
        print(f"Descargando datos de PostgreSQL par reporte {tipo_reporte} ...")
        df = pd.read_sql_query(query, connection)

        if tipo_reporte == "estadistico":
            generador_reportes_estadisticos(
                df_clientes=df, 
                fecha_inicio=filtros.get('inicio'), 
                fecha_fin=filtros.get('fin'),
                tipo_cliente=filtros.get('tipo'),
                canal=filtros.get('canal')
            )
        elif tipo_reporte == 'contable':
            generador_reportes_contables(
                df_movimientos=df, 
                agrupar_por=filtros.get('agrupar_por', 'cliente')
            )
        elif tipo_reporte == 'auditoria':
            generador_reportes_auditoria(df)
            
    except Exception as error:
        print(f"Error critico en el proceso: {error}")
        if connection:
            connection.rollback()
    finally:
        if connection is not None:
            connection.close()
            print("Conexión cerrada.")

if __name__ == "__main__":
    print("Iniciando prueba rapida")
    mis_filtros = {'inicio': '2020-01-01', 'fin': '2026-12-31', 'tipo': 'Todos', 'canal': 'Todos'}
    obtener_datos_y_generar("estadistico", mis_filtros)