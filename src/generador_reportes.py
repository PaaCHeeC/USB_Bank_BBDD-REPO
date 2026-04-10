import pandas as pd
from fpdf import FPDF  # Importación corregida para fpdf2
from fpdf.fonts import FontFace
import os
from datetime import datetime
from creador_dir_reportes import creacion_de_carpeta_reportes

PASTEL_BLUE = (225, 238, 250)


def obtener_etiqueta_reporte(subcarpeta: str) -> str:
    if subcarpeta == "reportes_contables":
        return "Reporte Contable"
    if subcarpeta == "reportes_estadisticos":
        return "Reporte Estadístico"
    if subcarpeta == "reportes_auditoria":
        return "Reporte de Auditoría"
    return "Reporte"


def formatear_rango_fechas(fecha_inicio, fecha_fin) -> str:
    if not fecha_inicio and not fecha_fin:
        return "Todos los registros hasta la fecha"
    return f"Desde {fecha_inicio} Hasta {fecha_fin}"


class PDFReporte(FPDF):
    def __init__(self, orientacion, etiqueta_reporte):
        super().__init__(orientation=orientacion)
        self.etiqueta_reporte = etiqueta_reporte

    def footer(self):
        self.set_y(-10)
        self.set_font("helvetica", size=8)
        self.cell(
            0,
            5,
            f"{self.etiqueta_reporte} - USB Bank - Equipo A",
            align="L",
        )
        self.cell(0, 5, f"Nro Pag {self.page_no()}", align="R")


##IMPORTANTE:
##Debe tener el modulo virtualenv para que el programa funcione bien, ademas de activar el venv antes de ejecutar
# el codigo, corriendo el script 'c:\users\usuario\myenv\Scripts\activate'

# Aqui creamos los directorios necesarios para guardar los reportes, si es que no existen
creacion_de_carpeta_reportes("reportes_generados")
carpetas_reportes = [
    "reportes_estadisticos",
    "reportes_contables",
    "reportes_auditoria",
]
ruta = "reportes_generados"
for carpeta in carpetas_reportes:
    ruta_completa = os.path.join(ruta, carpeta)
    os.makedirs(ruta_completa, exist_ok=True)
print("Creacion de las carpetas de reportes completada.")


# Función exportar_pdf, que convierte los reportes de txt a pdf
def exportar_pdf(
    datos,
    nombre_reporte,
    subcarpeta,
    resumen_tabla=None,
    metadata_lineas=None,
):
    columnas = [str(col) for col in datos.columns.tolist()]
    orientacion = (
        "L" if (subcarpeta == "reportes_contables" or len(columnas) > 7) else "P"
    )
    etiqueta_reporte = obtener_etiqueta_reporte(subcarpeta)

    pdf = PDFReporte(orientacion=orientacion, etiqueta_reporte=etiqueta_reporte)
    pdf.add_page()

    pdf.set_line_width(0.2)

    # Encabezado del pdf
    pdf.set_font("helvetica", style="B", size=16)
    pdf.cell(
        0,
        10,
        f"USB Bank - {etiqueta_reporte}",
        align="C",
        new_x="LMARGIN",
        new_y="NEXT",
    )

    # Fecha del pdf
    pdf.set_font("helvetica", style="I", size=10)
    fecha_actual = datetime.now().strftime("%d/%m/%Y %H:%M:%S")
    pdf.cell(
        0,
        10,
        f"Fecha de emisión: {fecha_actual}",
        align="C",
        new_x="LMARGIN",
        new_y="NEXT",
    )
    pdf.ln(5)

    filas = datos.astype(str).values.tolist()

    # dibujo la tabla especificada
    tam_fuente_tabla = 8 if len(columnas) > 10 else 9
    pdf.set_font("helvetica", size=tam_fuente_tabla)
    encabezado_style = (
        FontFace(emphasis="B", fill_color=PASTEL_BLUE)
        if subcarpeta == "reportes_contables"
        else FontFace(emphasis="B")
    )
    with pdf.table(text_align="CENTER", headings_style=encabezado_style) as table:
        encabezado = table.row()
        for col_name in columnas:
            encabezado.cell(col_name)

        pdf.set_font(style="")
        for fila_datos in filas:
            fila = table.row()
            for item in fila_datos:
                fila.cell(item)

    if subcarpeta == "reportes_estadisticos":
        pdf.ln(5)
        pdf.set_font("helvetica", style="I", size=10)
        pdf.cell(
            0,
            10,
            f"Saldo Total: ${datos['Saldo_Total'].astype(float).sum():,.2f}\n",
            align="L",
            new_x="LMARGIN",
            new_y="NEXT",
        )

    if resumen_tabla:
        pdf.ln(4)
        pdf.set_font("helvetica", style="B", size=11)
        pdf.cell(0, 8, "Resumen del Reporte", new_x="LMARGIN", new_y="NEXT")

        pdf.set_font("helvetica", size=10)
        page_width_usable = pdf.w - pdf.l_margin - pdf.r_margin
        label_w = page_width_usable * 0.7
        value_w = page_width_usable * 0.3
        for etiqueta, valor in resumen_tabla:
            pdf.set_fill_color(*PASTEL_BLUE)
            pdf.cell(label_w, 8, str(etiqueta), border=1, align="L", fill=True)
            pdf.cell(value_w, 8, str(valor), border=1, align="R", fill=True)
            pdf.ln(8)

    if metadata_lineas:
        pdf.ln(4)
        pdf.set_font("helvetica", style="B", size=10)
        pdf.cell(0, 8, "Parametros del Reporte", new_x="LMARGIN", new_y="NEXT")
        pdf.set_font("helvetica", size=10)
        for linea in metadata_lineas:
            pdf.cell(0, 7, str(linea), new_x="LMARGIN", new_y="NEXT")

    # Guardo el archivo
    if not nombre_reporte.endswith(".pdf"):
        nombre_reporte += ".pdf"

    ruta_destino = os.path.join("reportes_generados", subcarpeta, nombre_reporte)
    pdf.output(ruta_destino)
    print(f"[PDF OK] Reporte guardado en: {ruta_destino}")


# generador_reportes_estadisticos genera los reportes estadisticos con los requerimientos solicitados
# la cual genera un txt y un pdf como reportes
def generador_reportes_estadisticos(
    df_clientes,
    fecha_inicio=None,
    fecha_fin=None,
    tipo_cliente=None,
    canal=None,
    formato="ambos",
):
    if df_clientes.empty:
        print(
            "[AVISO] No hay datos en la base de datos para generar este reporte estadístico."
        )

    clientes_filtrado = df_clientes.copy()
    fecha_inicio_reporte = fecha_inicio
    fecha_fin_reporte = fecha_fin

    if "Fecha_Registro" in clientes_filtrado.columns:
        clientes_filtrado["Fecha_Registro"] = pd.to_datetime(
            clientes_filtrado["Fecha_Registro"]
        )

        if fecha_inicio and fecha_fin:
            fecha_inicio = pd.to_datetime(fecha_inicio)
            fecha_fin = pd.to_datetime(fecha_fin)
            clientes_filtrado = clientes_filtrado[
                (clientes_filtrado["Fecha_Registro"] >= fecha_inicio)
                & (clientes_filtrado["Fecha_Registro"] <= fecha_fin)
            ]
    if tipo_cliente and tipo_cliente != "Todos":
        clientes_filtrado = clientes_filtrado[
            clientes_filtrado["Tipo_Cliente"] == tipo_cliente
        ]

    if canal and canal != "Todos":
        clientes_filtrado = clientes_filtrado[
            clientes_filtrado["Canal_Afiliacion"] == canal
        ]

    columnas_deseadas = [
        "ID_Cliente",
        "Nombre",
        "Tipo_Cliente",
        "Total_Productos",
        "Saldo_Total",
    ]
    columnas_reporte = [
        col for col in columnas_deseadas if col in clientes_filtrado.columns
    ]

    df_final = clientes_filtrado[columnas_reporte]

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    rango_fechas = formatear_rango_fechas(fecha_inicio_reporte, fecha_fin_reporte)

    if formato.lower() in ["txt", "ambos"]:
        etiqueta_tipo = (
            tipo_cliente if tipo_cliente and tipo_cliente != "Todos" else "General"
        )
        nombre_archivo = f"reportes_generados/reportes_estadisticos/Reporte_Estadistico_{etiqueta_tipo}_{timestamp}.txt"

        with open(nombre_archivo, "w", encoding="utf-8") as f:
            f.write("REPORTE ESTADISTICO EJECUTIVO (CBO/CEO)\n")
            f.write(
                f"Dia del reporte: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
            )
            f.write(f"{rango_fechas} | Tipo: {tipo_cliente} | Canal: {canal}\n")
            f.write("-" * 85 + "\n\n")

            if df_final.empty:
                f.write("No se encontraron clientes con los criterios especificados.\n")
            else:
                f.write(df_final.to_string(index=False))
                f.write("\n\n" + "-" * 80 + "\n")
                if "Saldo_Total" in df_final.columns:
                    f.write(
                        f"SALDO TOTAL: ${df_final['Saldo_Total'].astype(float).sum():,.2f}\n"
                    )

        print(f"[TXT OK] Reporte estadístico generado en: {nombre_archivo}")

    # genero el pdf en cuestion
    if formato.lower() in ["pdf", "ambos"]:
        etiqueta_tipo = (
            tipo_cliente if tipo_cliente and tipo_cliente != "Todos" else "General"
        )
        nombre_pdf = f"Reporte_Estadistico_{etiqueta_tipo}_{timestamp}.pdf"
        metadata_pdf_estadistico = [
            rango_fechas,
            f"Tipo: {tipo_cliente} | Canal: {canal}",
        ]
        exportar_pdf(
            df_final,
            nombre_pdf,
            "reportes_estadisticos",
            metadata_lineas=metadata_pdf_estadistico,
        )


# hace lo mismo que generador_reportes_estadisticos, pero con reportes contables
def generador_reportes_contables(
    df_movimientos,
    agrupar_por: str,
    formato="ambos",
    fecha_inicio=None,
    fecha_fin=None,
    estado_movimiento="Todos",
):
    sin_datos = df_movimientos.empty
    total_clientes_activos_bbdd = None
    total_cuentas_activas_bbdd = None
    total_tarjetas_activas_bbdd = None

    if sin_datos:
        print("[AVISO] No hay datos de movimientos para generar este reporte contable.")

    columnas_validas = {
        "cuenta": "Cuenta",
        "cliente": "ID_Cliente",
        "canal": "Canal_Descripcion",
        "tarjeta": "Tarjeta",
    }

    if agrupar_por.lower() not in columnas_validas:
        print("Error: debe agruparse por 'cuenta', 'cliente', 'canal', 'tarjeta'")
        return

    columna_agrupacion = columnas_validas[agrupar_por.lower()]
    columnas_requeridas = {
        "Ingreso",
        "Egreso",
        "Neto",
        "Comision",
        "Referencia",
        "Tipo_Movimiento",
    }

    usa_formato_v2 = (
        (not sin_datos)
        and (columna_agrupacion in df_movimientos.columns)
        and columnas_requeridas.issubset(df_movimientos.columns)
    )

    if sin_datos:
        df_pivot = pd.DataFrame(
            [
                {
                    "Mensaje": "No hay información con los filtros seleccionados.",
                    "Fecha_Inicio": str(fecha_inicio),
                    "Fecha_Fin": str(fecha_fin),
                    "Estado": str(estado_movimiento),
                    "Agrupado_Por": agrupar_por.upper(),
                }
            ]
        )
    elif usa_formato_v2:
        df_trabajo = df_movimientos.copy()

        if "Total_Clientes_Activos_BBDD" in df_trabajo.columns:
            total_clientes_activos_bbdd = int(
                pd.to_numeric(
                    df_trabajo["Total_Clientes_Activos_BBDD"], errors="coerce"
                )
                .fillna(0)
                .max()
            )
        if "Total_Cuentas_Activas_BBDD" in df_trabajo.columns:
            total_cuentas_activas_bbdd = int(
                pd.to_numeric(df_trabajo["Total_Cuentas_Activas_BBDD"], errors="coerce")
                .fillna(0)
                .max()
            )
        if "Total_Tarjetas_Activas_BBDD" in df_trabajo.columns:
            total_tarjetas_activas_bbdd = int(
                pd.to_numeric(
                    df_trabajo["Total_Tarjetas_Activas_BBDD"], errors="coerce"
                )
                .fillna(0)
                .max()
            )

        # Asegura tipos numéricos para todos los cálculos agregados.
        for columna_monto in ["Ingreso", "Egreso", "Neto", "Comision"]:
            if columna_monto in df_trabajo.columns:
                df_trabajo[columna_monto] = pd.to_numeric(
                    df_trabajo[columna_monto], errors="coerce"
                ).fillna(0)

        if agrupar_por.lower() == "tarjeta":
            df_trabajo = df_trabajo[
                df_trabajo["Tarjeta"].notna() & (df_trabajo["Tarjeta"] != "N/A")
            ]

        if df_trabajo.empty:
            df_pivot = pd.DataFrame(
                [
                    {
                        "Mensaje": "No hay información con los filtros seleccionados.",
                        "Fecha_Inicio": str(fecha_inicio),
                        "Fecha_Fin": str(fecha_fin),
                        "Estado": str(estado_movimiento),
                        "Agrupado_Por": agrupar_por.upper(),
                    }
                ]
            )
        else:
            columnas_contexto = {
                "cliente": [
                    "ID_Cliente",
                    "Titular",
                    "Estado_Cliente",
                    "Nro_Cuentas_Activas",
                    "Nro_Tarjetas_Activas",
                ],
                "cuenta": ["Cuenta", "Titular", "Estado_Cuenta"],
                "canal": ["Canal_Descripcion", "Onboardings_Canal"],
                "tarjeta": ["Tarjeta", "Titular", "Tipo_Tarjeta", "Estado_Tarjeta"],
            }

            group_cols = [
                col
                for col in columnas_contexto[agrupar_por.lower()]
                if col in df_trabajo.columns
            ]
            if columna_agrupacion not in group_cols:
                group_cols = [columna_agrupacion] + group_cols

            df_resumen = (
                df_trabajo.groupby(group_cols, dropna=False)
                .agg(
                    Ingresos=("Ingreso", "sum"),
                    Egresos=("Egreso", "sum"),
                    Neto=("Neto", "sum"),
                    Comisiones=("Comision", "sum"),
                    Cantidad_Movimientos=("Referencia", "nunique"),
                )
                .reset_index()
            )

            alias_tipos_mov = {
                "transferencia interbancaria": "Mov_Transferencia_Interbancaria",
                "pago por ecommerce": "Mov_Pago_Ecommerce",
                "pago por punto de venta": "Mov_Pago_POS",
                "retiro en cajero automatico": "Mov_Retiro_ATM",
                "pago movil": "Mov_Pago_Movil",
            }

            if agrupar_por.lower() == "tarjeta":
                columnas_tipo_objetivo = [
                    "Mov_Pago_Ecommerce",
                    "Mov_Pago_POS",
                    "Mov_Retiro_ATM",
                ]
            else:
                columnas_tipo_objetivo = [
                    "Mov_Transferencia_Interbancaria",
                    "Mov_Pago_Ecommerce",
                    "Mov_Pago_POS",
                    "Mov_Retiro_ATM",
                    "Mov_Pago_Movil",
                ]

            df_tipo_mov = df_trabajo.copy()
            df_tipo_mov["Tipo_Mov_Alias"] = (
                df_tipo_mov["Tipo_Movimiento"].astype(str).str.strip().str.lower()
            ).map(alias_tipos_mov)
            df_tipo_mov["Monto_Movido"] = df_tipo_mov["Ingreso"] + df_tipo_mov["Egreso"]
            df_tipo_mov = df_tipo_mov[
                df_tipo_mov["Tipo_Mov_Alias"].isin(columnas_tipo_objetivo)
            ]

            if df_tipo_mov.empty:
                df_tipos = df_resumen[group_cols].copy()
                for columna_tipo in columnas_tipo_objetivo:
                    df_tipos[columna_tipo] = 0
            else:
                df_tipos = (
                    df_tipo_mov.groupby(group_cols + ["Tipo_Mov_Alias"], dropna=False)[
                        "Monto_Movido"
                    ]
                    .sum()
                    .unstack(fill_value=0)
                    .reset_index()
                )
                for columna_tipo in columnas_tipo_objetivo:
                    if columna_tipo not in df_tipos.columns:
                        df_tipos[columna_tipo] = 0

            df_pivot = df_resumen.merge(df_tipos, on=group_cols, how="left")
            for columna_tipo in columnas_tipo_objetivo:
                if columna_tipo in df_pivot.columns:
                    df_pivot[columna_tipo] = pd.to_numeric(
                        df_pivot[columna_tipo], errors="coerce"
                    ).fillna(0)

            if agrupar_por.lower() == "canal":
                df_pivot = df_pivot.rename(
                    columns={"Cantidad_Movimientos": "Nro_Movimientos"}
                )
                columnas_canal = [
                    "Canal_Descripcion",
                    "Onboardings_Canal",
                    "Ingresos",
                    "Egresos",
                    "Neto",
                    "Comisiones",
                    "Nro_Movimientos",
                ]
                df_pivot = df_pivot[
                    [col for col in columnas_canal if col in df_pivot.columns]
                ]
                df_pivot = df_pivot.sort_values(by="Nro_Movimientos", ascending=False)
            else:
                df_pivot = df_pivot.sort_values(by="Neto", ascending=False)

            if agrupar_por.lower() == "cuenta" and "Cuenta" in df_pivot.columns:
                df_pivot = df_pivot.rename(columns={"Cuenta": "Nro_Cuenta"})

            if agrupar_por.lower() == "tarjeta" and "Tarjeta" in df_pivot.columns:
                df_pivot = df_pivot.rename(columns={"Tarjeta": "Nro_Tarjeta"})

            # Renombres solicitados para compactar encabezados en reportes contables.
            renombres_contables = {
                "Estado_Cliente": "Estado",
                "Estado_Cuenta": "Estado",
                "Estado_Tarjeta": "Estado",
                "Cantidad_Movimientos": "Nro_Movimientos",
                "Mov_Transferencia_Interbancaria": "Mov_Transferencia",
            }
            df_pivot = df_pivot.rename(columns=renombres_contables)
    else:
        if (
            columna_agrupacion not in df_movimientos.columns
            or "Monto" not in df_movimientos.columns
            or "Tipo_Movimiento" not in df_movimientos.columns
        ):
            print(
                f"[ERROR] Faltan columnas en los datos para agrupar por {agrupar_por}."
            )
            df_pivot = pd.DataFrame(
                [
                    {
                        "Mensaje": f"No se pudo construir el reporte: faltan columnas para agrupar por {agrupar_por}."
                    }
                ]
            )
        else:
            df_pivot = pd.pivot_table(
                df_movimientos,
                values="Monto",
                index=columna_agrupacion,
                columns="Tipo_Movimiento",
                aggfunc="sum",
                fill_value=0,
            ).reset_index()

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    resumen_pdf_contable = []
    rango_fechas = formatear_rango_fechas(fecha_inicio, fecha_fin)

    if usa_formato_v2 and not df_pivot.empty and "Ingresos" in df_pivot.columns:
        resumen_pdf_contable.append(
            ("TOTAL INGRESOS", f"{df_pivot['Ingresos'].sum():,.2f}")
        )
        resumen_pdf_contable.append(
            ("TOTAL EGRESOS", f"{df_pivot['Egresos'].sum():,.2f}")
        )
        resumen_pdf_contable.append(("NETO TOTAL", f"{df_pivot['Neto'].sum():,.2f}"))
        resumen_pdf_contable.append(
            ("TOTAL COMISIONES", f"{df_pivot['Comisiones'].sum():,.2f}")
        )

        columna_volumen_pdf = (
            "Nro_Movimientos"
            if "Nro_Movimientos" in df_pivot.columns
            else "Volumen_Transacciones"
            if "Volumen_Transacciones" in df_pivot.columns
            else "Cantidad_Movimientos"
        )
        if columna_volumen_pdf in df_pivot.columns:
            resumen_pdf_contable.append(
                ("MOVIMIENTOS ANALIZADOS", int(df_pivot[columna_volumen_pdf].sum()))
            )

        if agrupar_por.lower() == "cliente" and total_clientes_activos_bbdd is not None:
            resumen_pdf_contable.append(
                ("TOTAL CLIENTES ACTIVOS", total_clientes_activos_bbdd)
            )

        if agrupar_por.lower() == "cuenta" and total_cuentas_activas_bbdd is not None:
            resumen_pdf_contable.append(
                ("TOTAL CUENTAS ACTIVAS", total_cuentas_activas_bbdd)
            )

        if agrupar_por.lower() == "tarjeta" and total_tarjetas_activas_bbdd is not None:
            resumen_pdf_contable.append(
                ("TOTAL TARJETAS ACTIVAS", total_tarjetas_activas_bbdd)
            )

    if formato.lower() in ["txt", "ambos"]:
        nombre_archivo = f"reportes_generados/reportes_contables/Reporte_Contable_Para_{agrupar_por.capitalize()}_{timestamp}.txt"

        with open(nombre_archivo, "w", encoding="utf-8") as f:
            f.write("REPORTE CONTABLE DE INGRESOS Y EGRESOS\n")
            f.write(
                f"Dia del reporte: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
            )
            f.write(f"Agrupado por: {agrupar_por.upper()}\n")
            f.write(f"{rango_fechas} | Estado: {estado_movimiento}\n")
            f.write("-" * 50 + "\n\n")
            f.write(df_pivot.to_string(index=False))

            if usa_formato_v2 and not df_pivot.empty and "Ingresos" in df_pivot.columns:
                f.write("\n\n" + "-" * 50 + "\n")
                f.write(f"TOTAL INGRESOS: {df_pivot['Ingresos'].sum():,.2f}\n")
                f.write(f"TOTAL EGRESOS: {df_pivot['Egresos'].sum():,.2f}\n")
                f.write(f"NETO TOTAL: {df_pivot['Neto'].sum():,.2f}\n")
                f.write(f"TOTAL COMISIONES: {df_pivot['Comisiones'].sum():,.2f}\n")
                columna_volumen = (
                    "Nro_Movimientos"
                    if "Nro_Movimientos" in df_pivot.columns
                    else "Volumen_Transacciones"
                    if "Volumen_Transacciones" in df_pivot.columns
                    else "Cantidad_Movimientos"
                )
                if columna_volumen in df_pivot.columns:
                    f.write(
                        f"MOVIMIENTOS ANALIZADOS: {int(df_pivot[columna_volumen].sum())}\n"
                    )

                if (
                    agrupar_por.lower() == "cliente"
                    and total_clientes_activos_bbdd is not None
                ):
                    f.write(f"TOTAL CLIENTES ACTIVOS: {total_clientes_activos_bbdd}\n")

                if (
                    agrupar_por.lower() == "cuenta"
                    and total_cuentas_activas_bbdd is not None
                ):
                    f.write(f"TOTAL CUENTAS ACTIVAS: {total_cuentas_activas_bbdd}\n")

                if (
                    agrupar_por.lower() == "tarjeta"
                    and total_tarjetas_activas_bbdd is not None
                ):
                    f.write(f"TOTAL TARJETAS ACTIVAS: {total_tarjetas_activas_bbdd}\n")

        print(f"[TXT OK] Reporte contable generado en: {nombre_archivo}")

    # genera el PDF para el reporte contable
    if formato.lower() in ["pdf", "ambos"]:
        nombre_pdf = f"Reporte_Contable_Para_{agrupar_por}_{timestamp}.pdf"
        metadata_pdf_contable = [
            f"Agrupado por: {agrupar_por.upper()}",
            f"{rango_fechas} | Estado: {estado_movimiento}",
        ]
        exportar_pdf(
            df_pivot,
            nombre_pdf,
            "reportes_contables",
            resumen_tabla=resumen_pdf_contable,
            metadata_lineas=metadata_pdf_contable,
        )


# Esta funcion hace el reporte de clientes eliminados por inactividad
def generador_reportes_auditoria(df_auditoria, formato="ambos"):
    if df_auditoria.empty:
        print("[AVISO] No hay clientes eliminados registrados en la auditoría.")
        df_auditoria = pd.DataFrame(
            [
                {
                    "Mensaje": "No hay información con los filtros seleccionados o no hubo eliminaciones."
                }
            ]
        )

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

    if formato.lower() in ["txt", "ambos"]:
        nombre_archivo = f"reportes_generados/reportes_auditoria/Reporte_Auditoria_Limpieza_{timestamp}.txt"

        with open(nombre_archivo, "w", encoding="utf-8") as f:
            f.write("REPORTE DE AUDITORÍA: CLIENTES ELIMINADOS POR INACTIVIDAD\n")
            f.write(
                f"Día de ejecución: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
            )
            f.write("-" * 85 + "\n\n")
            f.write(df_auditoria.to_string(index=False))

        print(f"[TXT OK] Reporte de auditoría generado en: {nombre_archivo}")

    if formato.lower() in ["pdf", "ambos"]:
        nombre_pdf = f"Reporte_Auditoria_Limpieza_{timestamp}.pdf"
        exportar_pdf(df_auditoria, nombre_pdf, "reportes_auditoria")
