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

        query = None
        query_params = None

        if tipo_reporte == "estadistico":
            fecha_inicio = filtros.get("inicio")
            fecha_fin = filtros.get("fin")

            query = """
                SELECT
                    "CLIENTE".id_cliente AS "ID_Cliente",
                    COALESCE("CLIENTE_NATURAL".primer_nombre || ' ' || "CLIENTE_NATURAL".apellido,
                             "CLIENTE_JURIDICO".nombre_org) AS "Nombre",
                    "CLIENTE".tipo_cliente AS "Tipo_Cliente",
                    "CANAL".tipo_canal AS "Canal_Afiliacion",
                    COALESCE("CUENTA".cuentas, 0) AS "Total_Productos",
                    COALESCE("CUENTA".saldo_total_cuenta, 0.00) AS "Saldo_Total",
                    "CLIENTE".fecha_registro AS "Fecha_Registro",
                    kpi.total_clientes_activos AS "Total_Clientes_Activos",
                    kpi.total_cuentas_activas AS "Total_Cuentas_Activas",
                    kpi.total_tarjetas_activas AS "Total_Tarjetas_Activas",
                    kpi.onboarding_portal_web AS "Onboarding_Portal_Web",
                    kpi.onboarding_app_movil AS "Onboarding_App_Movil",
                    kpi.onboarding_ivr_otros AS "Onboarding_IVR_Otros",
                    mov.total_ingresos AS "Total_Ingresos_Periodo",
                    mov.total_egresos AS "Total_Egresos_Periodo"
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
                CROSS JOIN (
                    SELECT
                        COUNT(*) FILTER (WHERE LOWER(c.estado) = 'activo') AS total_clientes_activos,
                        (SELECT COUNT(*) FROM usb_bank."CUENTA" cu WHERE LOWER(cu.estado) = 'activa') AS total_cuentas_activas,
                        (SELECT COUNT(*) FROM usb_bank."TARJETA" t WHERE LOWER(t.estado) = 'activa') AS total_tarjetas_activas,
                        COUNT(*) FILTER (
                            WHERE LOWER(can.descripcion) LIKE '%%portal web%%'
                        ) AS onboarding_portal_web,
                        COUNT(*) FILTER (
                            WHERE LOWER(can.descripcion) LIKE '%%app movil%%'
                        ) AS onboarding_app_movil,
                        COUNT(*) FILTER (
                            WHERE LOWER(can.descripcion) NOT LIKE '%%portal web%%'
                              AND LOWER(can.descripcion) NOT LIKE '%%app movil%%'
                        ) AS onboarding_ivr_otros
                    FROM usb_bank."CLIENTE" c
                    JOIN usb_bank."CANAL" can ON can.id_canal = c.id_canal_onboarding
                    WHERE LOWER(c.estado) = 'activo'
                ) kpi
                CROSS JOIN (
                    WITH movimientos_filtrados AS (
                        SELECT m.*
                        FROM usb_bank."MOVIMIENTO" m
                        WHERE (%s IS NULL OR m.fecha >= %s::timestamp)
                          AND (%s IS NULL OR m.fecha < (%s::date + INTERVAL '1 day'))
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
                        COALESCE(SUM(mu.ingreso), 0.00) AS total_ingresos,
                        COALESCE(SUM(mu.egreso), 0.00) AS total_egresos
                    FROM movimientos_unificados mu
                    JOIN usb_bank."CUENTA" cu_mov ON mu.nro_cuenta = cu_mov.nro_cuenta
                    WHERE (mu.ingreso + mu.egreso) > 0
                ) mov
                ORDER BY "CLIENTE".id_cliente;
            """
            query_params = (
                fecha_inicio,
                fecha_inicio,
                fecha_fin,
                fecha_fin,
            )

        elif tipo_reporte == "contable":
            fecha_inicio = filtros.get("inicio")
            fecha_fin = filtros.get("fin")
            estado_movimiento = (filtros.get("estado_movimiento") or "Todos").strip()

            query = """
                WITH movimientos_filtrados AS (
                    SELECT m.*
                    FROM "usb_bank"."MOVIMIENTO" m
                    WHERE (%s IS NULL OR m.fecha >= %s::timestamp)
                      AND (%s IS NULL OR m.fecha < (%s::date + INTERVAL '1 day'))
                        AND (LOWER(%s) = 'todos' OR LOWER(m.estado) = LOWER(%s))
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
                        'egreso' AS direccion,
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
                        'ingreso' AS direccion,
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
                    cu.id_cliente AS "ID_Cliente",
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
            """
            query_params = (
                fecha_inicio,
                fecha_inicio,
                fecha_fin,
                fecha_fin,
                estado_movimiento,
                estado_movimiento,
            )

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
