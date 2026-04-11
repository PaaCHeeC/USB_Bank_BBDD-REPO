import psycopg2
import pandas as pd
import warnings

from config import config
from generador_reportes import (
    generador_reportes_estadisticos,
    generador_reportes_contables,
    generador_reportes_auditoria,
)

warnings.filterwarnings("ignore", category=UserWarning)


def obtener_datos_y_generar(tipo_reporte, filtros):
    connection = None

    try:
        params = config()
        print("Conectando con la base de datos en PostgreSQL ...")
        connection = psycopg2.connect(**params)
        cursor = connection.cursor()

        query = None
        query_params = None

        if tipo_reporte == "estadistico":
            fecha_inicio = filtros.get("inicio") if filtros.get("inicio") else None
            fecha_fin = filtros.get("fin") if filtros.get("fin") else None

            query = 'SELECT * FROM "usb_bank"."fn_reporte_estadistico"(%s, %s);'
            query_params = (fecha_inicio, fecha_fin)

        elif tipo_reporte == "contable":
            fecha_inicio = filtros.get("inicio") if filtros.get("inicio") else None
            fecha_fin = filtros.get("fin") if filtros.get("fin") else None
            estado_movimiento = (filtros.get("estado_movimiento") or "Todos").strip()

            query = 'SELECT * FROM "usb_bank"."fn_reporte_contable_detalle"(%s, %s, %s);'
            query_params = (fecha_inicio, fecha_fin, estado_movimiento)

        elif tipo_reporte == "auditoria":
            print("Iniciando rutina de limpieza de inactivos...")

            query_delete = """
                SET search_path TO "usb_bank";

                DELETE FROM "usb_bank"."CLIENTE" c
                WHERE c.id_cliente IN (
                    SELECT cu.id_cliente
                    FROM "usb_bank"."CUENTA" cu
                    JOIN "usb_bank"."TARJETA" t ON cu.nro_cuenta = t.nro_cuenta
                )
                AND c.id_cliente NOT IN (
                    SELECT cu.id_cliente
                    FROM "usb_bank"."CUENTA" cu
                    JOIN "usb_bank"."TARJETA" t ON cu.nro_cuenta = t.nro_cuenta
                    JOIN "usb_bank"."MOVIMIENTO_PAGO_POS" mp ON t.nro_tarjeta = mp.nro_tarjeta
                    JOIN "usb_bank"."MOVIMIENTO" m ON mp.nro_referencia = m.nro_referencia
                    WHERE m.fecha >= CURRENT_DATE - INTERVAL '1 month'

                    UNION

                    SELECT cu.id_cliente
                    FROM "usb_bank"."CUENTA" cu
                    JOIN "usb_bank"."TARJETA" t ON cu.nro_cuenta = t.nro_cuenta
                    JOIN "usb_bank"."MOVIMIENTO_PAGO_ECOMMERCE" me ON t.nro_tarjeta = me.nro_tarjeta
                    JOIN "usb_bank"."MOVIMIENTO" m ON me.nro_referencia = m.nro_referencia
                    WHERE m.fecha >= CURRENT_DATE - INTERVAL '1 month'

                    UNION

                    SELECT cu.id_cliente
                    FROM "usb_bank"."CUENTA" cu
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
            print(
                f"Limpieza ejecutada. Se eliminaron {eliminados} clientes. Triggers disparados."
            )

            query = 'SELECT * FROM "usb_bank"."REPORTE_CLIENTES_ELIMINADOS" ORDER BY fecha_eliminacion DESC;'

        print(f"Descargando datos de PostgreSQL para reporte {tipo_reporte} ...")
        df = pd.read_sql_query(query, connection, params=query_params)
        
        if "ID" in df.columns and "ID_Cliente" not in df.columns:
            df.rename(columns={"ID": "ID_Cliente"}, inplace=True)

        formato = filtros.get("formato_deseado", "ambos")

        if tipo_reporte == "estadistico":
            generador_reportes_estadisticos(
                df_clientes=df,
                fecha_inicio=filtros.get("inicio"),
                fecha_fin=filtros.get("fin"),
                tipo_cliente=filtros.get("tipo"),
                canal=filtros.get("canal"),
                formato=formato,
            )
        elif tipo_reporte == "contable":
            generador_reportes_contables(
                df_movimientos=df,
                agrupar_por=filtros.get("agrupar_por", "cliente"),
                formato=formato,
                fecha_inicio=filtros.get("inicio"),
                fecha_fin=filtros.get("fin"),
                estado_movimiento=filtros.get("estado_movimiento", "Todos"),
            )
        elif tipo_reporte == "auditoria":
            generador_reportes_auditoria(df_auditoria=df, formato=formato)

    except Exception as error:
        print(f"Error critico en el proceso: {error}")
        if connection:
            connection.rollback()
    finally:
        if connection is not None:
            connection.close()
            print("Conexión cerrada.")


if __name__ == "__main__":
    print("Iniciando prueba rápida")
    mis_filtros = {
        "inicio": "2020-01-01",
        "fin": "2026-12-31",
        "tipo": "Todos",
        "canal": "Todos",
        "agrupar_por": "cliente",
        "estado_movimiento": "Todos",
        "formato_deseado": "txt",
    }
    obtener_datos_y_generar("contable", mis_filtros)
