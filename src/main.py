import psycopg2
import pandas as pd
import warnings
from config import config
from generador_reportes import generador_reportes_estadisticos, generador_reportes_contables

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
                    c.id_cliente AS "ID_Cliente",
                    COALESCE(cn.primer_nombre || ' ' || cn.apellido, cj.nombre_org) AS "Nombre",
                    c.tipo_cliente AS "Tipo_Cliente",
                    can.tipo_canal AS "Canal_Afiliacion",
                    c.fecha_registro AS "Fecha_Registro",
                    (SELECT COUNT(*) FROM "usb_bank"."CUENTA" cu WHERE cu.id_cliente = c.id_cliente) AS "Total_Productos",
                    COALESCE((SELECT SUM(saldo) FROM "usb_bank"."CUENTA" cu WHERE cu.id_cliente = c.id_cliente), 0) AS "Saldo_Total"
                FROM "usb_bank"."CLIENTE" c
                LEFT JOIN "usb_bank"."CLIENTE_NATURAL" cn ON c.id_cliente = cn.id_cliente
                LEFT JOIN "usb_bank"."CLIENTE_JURIDICO" cj ON c.id_cliente = cj.id_cliente
                LEFT JOIN "usb_bank"."CANAL" can ON c.id_canal_onboarding = can.id_canal
                ORDER BY c.id_cliente
            """
        else:
            query = """
                SELECT 
                    m.nro_cuenta_origen AS "Cuenta",
                    cu.id_cliente AS "ID_Cliente",
                    can.tipo_canal AS "Canal_Tx",
                    COALESCE(pos.nro_tarjeta, ecom.nro_tarjeta, atm.nro_tarjeta, 'N/A') AS "Tarjeta",
                    tm.descripcion AS "Tipo_Movimiento",
                    (m.monto_ingreso + m.monto_egreso) AS "Monto"
                FROM "usb_bank"."MOVIMIENTO" m
                JOIN "usb_bank"."TIPO_MOVIMIENTO" tm ON m.id_tipo_mov = tm.id_tipo_mov
                JOIN "usb_bank"."CANAL" can ON m.id_canal = can.id_canal
                JOIN "usb_bank"."CUENTA" cu ON m.nro_cuenta_origen = cu.nro_cuenta
                LEFT JOIN "usb_bank"."MOVIMIENTO_PAGO_POS" pos ON m.nro_referencia = pos.nro_referencia
                LEFT JOIN "usb_bank"."MOVIMIENTO_PAGO_ECOMMERCE" ecom ON m.nro_referencia = ecom.nro_referencia
                LEFT JOIN "usb_bank"."MOVIMIENTO_RETIRO_ATM" atm ON m.nro_referencia = atm.nro_referencia
                ORDER BY cu.id_cliente
            """
            
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
        else:
            generador_reportes_contables(
                df_movimientos=df, 
                agrupar_por=filtros.get('agrupar_por', 'cliente')
            )
            
    except Exception as error:
        print(f"Error critico en el proceso: {error}")
    finally:
        if connection is not None:
            connection.close()
            print("Conexión cerrada.")

if __name__ == "__main__":
    print("Iniciando prueba rapida")
    mis_filtros = {'inicio': '2020-01-01', 'fin': '2026-12-31', 'tipo': 'Todos', 'canal': 'Todos'}
    obtener_datos_y_generar("estadistico", mis_filtros)