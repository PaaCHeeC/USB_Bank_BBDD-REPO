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


def formatear_numero_es(valor, decimales=2) -> str:
    numero = pd.to_numeric(valor, errors="coerce")
    if pd.isna(numero):
        numero = 0
    formato_base = f"{float(numero):,.{decimales}f}"
    return formato_base.replace(",", "_").replace(".", ",").replace("_", ".")


def formatear_monto_ves(valor) -> str:
    return formatear_numero_es(valor, decimales=2)


def formatear_columnas_monetarias(df, columnas_monetarias):
    df_formateado = df.copy()
    for columna in columnas_monetarias:
        if columna in df_formateado.columns:
            df_formateado[columna] = df_formateado[columna].apply(formatear_monto_ves)
    return df_formateado


def normalizar_nombre_columna_visual(columna, subcarpeta):
    nombre = " ".join(str(columna).replace("_", " ").split())
    if nombre == "ID Cliente":
        return "ID"
    if subcarpeta == "reportes_contables" and nombre in {"Comision", "Comisiones"}:
        return "Comisión"
    return nombre


def normalizar_nombres_columnas_visuales(columnas, subcarpeta):
    return [
        normalizar_nombre_columna_visual(columna, subcarpeta) for columna in columnas
    ]


def construir_anchos_contables_pdf(columnas):
    anchos_por_columna = {
        "ID_Cliente": 9,
        "Titular": 22,
        "Nro_Cuentas_Activas": 12,
        "Nro_Tarjetas_Activas": 12,
        "Cuenta": 18,
        "Nro_Cuenta": 18,
        "Tarjeta": 18,
        "Nro_Tarjeta": 18,
        "Canal_Descripcion": 22,
        "Tipo_Movimiento": 20,
        "Descripcion_Movimiento": 24,
        "Comisiones": 12,
        "Comision": 12,
        "Comisión": 12,
        "Ingreso": 13,
        "Egreso": 13,
        "Neto": 13,
        "Nro_Movimientos": 16,
        "Mov_Transferencia": 17,
        "Saldo_Previo": 14,
        "Saldo_Nuevo": 14,
    }
    return tuple(anchos_por_columna.get(columna, 14) for columna in columnas)


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
    secciones_resumen=None,
    saldo_total_texto=None,
    anchos_columnas=None,
):
    def texto_pdf(valor):
        if pd.isna(valor):
            return ""
        return str(valor)

    columnas = [str(col) for col in datos.columns.tolist()]
    columnas_pdf = normalizar_nombres_columnas_visuales(columnas, subcarpeta)
    subcarpetas_formato_corporativo = {
        "reportes_contables",
        "reportes_estadisticos",
        "reportes_auditoria",
    }
    orientacion = (
        "L"
        if (subcarpeta in subcarpetas_formato_corporativo or len(columnas) > 7)
        else "P"
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

    filas = datos.values.tolist()

    # dibujo la tabla especificada
    tam_fuente_tabla = 8 if len(columnas) > 10 else 9
    pdf.set_font("helvetica", size=tam_fuente_tabla)
    encabezado_style = (
        FontFace(emphasis="B", fill_color=PASTEL_BLUE)
        if subcarpeta in subcarpetas_formato_corporativo
        else FontFace(emphasis="B")
    )
    with pdf.table(
        text_align="CENTER", headings_style=encabezado_style, col_widths=anchos_columnas
    ) as table:
        encabezado = table.row()
        for col_name in columnas_pdf:
            encabezado.cell(col_name)

        pdf.set_font(style="")
        for fila_datos in filas:
            fila = table.row()
            for item in fila_datos:
                fila.cell(texto_pdf(item))

    if subcarpeta == "reportes_estadisticos":
        pdf.ln(5)
        pdf.set_font("helvetica", style="I", size=10)
        pdf.cell(
            0,
            10,
            f"Saldo Total: {saldo_total_texto or 'VES 0,00'}\n",
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
            pdf.cell(label_w, 8, texto_pdf(etiqueta), border=1, align="L", fill=True)
            pdf.cell(value_w, 8, texto_pdf(valor), border=1, align="R", fill=True)
            pdf.ln(8)

    if secciones_resumen:
        for seccion in secciones_resumen:
            titulo = seccion.get("titulo", "")
            filas_seccion = seccion.get("filas", [])
            if not filas_seccion:
                continue

            pdf.ln(4)
            pdf.set_font("helvetica", style="B", size=11)
            pdf.cell(0, 8, str(titulo), new_x="LMARGIN", new_y="NEXT")

            pdf.set_font("helvetica", size=10)
            page_width_usable = pdf.w - pdf.l_margin - pdf.r_margin
            label_w = page_width_usable * 0.7
            value_w = page_width_usable * 0.3

            for etiqueta, valor in filas_seccion:
                pdf.set_fill_color(*PASTEL_BLUE)
                pdf.cell(
                    label_w, 8, texto_pdf(etiqueta), border=1, align="L", fill=True
                )
                pdf.cell(value_w, 8, texto_pdf(valor), border=1, align="R", fill=True)
                pdf.ln(8)

    if metadata_lineas:
        pdf.ln(4)
        pdf.set_font("helvetica", style="B", size=10)
        pdf.cell(0, 8, "Parametros del Reporte", new_x="LMARGIN", new_y="NEXT")
        pdf.set_font("helvetica", size=10)
        for linea in metadata_lineas:
            pdf.cell(0, 7, texto_pdf(linea), new_x="LMARGIN", new_y="NEXT")

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
        letra_tipo = "N" if "Natural" in tipo_cliente else "J"
        clientes_filtrado = clientes_filtrado[
            clientes_filtrado["Tipo_Cliente"] == letra_tipo
        ]

    if canal and canal != "Todos":
        if "Web" in canal:
            letra_canal = "W"
        elif "Movil" in canal or "Móvil" in canal:
            letra_canal = "M"
        else:
            letra_canal = "O"

        clientes_filtrado = clientes_filtrado[
            clientes_filtrado["Canal_Onboarding"] == letra_canal
        ]

    columnas_deseadas = [
        "ID_Cliente",
        "Titular",
        "Tipo_Cliente",
        "Canal_Onboarding",
        "Total_Cuentas",
        "Total_Tarjetas",
        "Fecha_Registro",
        "Debe",
        "Haber",
        "Saldo_Total",
    ]
    columnas_reporte = [
        col for col in columnas_deseadas if col in clientes_filtrado.columns
    ]

    df_final = clientes_filtrado[columnas_reporte]
    saldo_total_general = 0.0
    if "Saldo_Total" in df_final.columns:
        saldo_total_general = float(
            pd.to_numeric(df_final["Saldo_Total"], errors="coerce").fillna(0).sum()
        )
    df_final_export = formatear_columnas_monetarias(df_final, ["Saldo_Total"])

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    rango_fechas = formatear_rango_fechas(fecha_inicio_reporte, fecha_fin_reporte)
    total_ingresos_periodo = 0.0
    total_egresos_periodo = 0.0
    total_clientes_activos = 0
    total_cuentas_activas = 0
    total_tarjetas_activas = 0
    onboarding_portal_web = 0
    onboarding_app_movil = 0

    if not df_clientes.empty:
        if "Debe" in df_final.columns:
            total_ingresos_periodo = float(
                pd.to_numeric(df_final["Debe"], errors="coerce").fillna(0).sum()
            )
        if "Haber" in df_final.columns:
            total_egresos_periodo = float(
                pd.to_numeric(df_final["Haber"], errors="coerce").fillna(0).sum()
            )
        if "Total_Clientes_Activos" in df_clientes.columns:
            total_clientes_activos = int(
                pd.to_numeric(df_clientes["Total_Clientes_Activos"], errors="coerce")
                .fillna(0)
                .max()
            )
        if "Total_Cuentas_Activas" in df_clientes.columns:
            total_cuentas_activas = int(
                pd.to_numeric(df_clientes["Total_Cuentas_Activas"], errors="coerce")
                .fillna(0)
                .max()
            )
        if "Total_Tarjetas_Activas" in df_clientes.columns:
            total_tarjetas_activas = int(
                pd.to_numeric(df_clientes["Total_Tarjetas_Activas"], errors="coerce")
                .fillna(0)
                .max()
            )
        if "Onboarding_Portal_Web" in df_clientes.columns:
            onboarding_portal_web = int(
                pd.to_numeric(df_clientes["Onboarding_Portal_Web"], errors="coerce")
                .fillna(0)
                .max()
            )
        if "Onboarding_App_Movil" in df_clientes.columns:
            onboarding_app_movil = int(
                pd.to_numeric(df_clientes["Onboarding_App_Movil"], errors="coerce")
                .fillna(0)
                .max()
            )
    balance_neto_periodo = total_ingresos_periodo - total_egresos_periodo

    if formato.lower() in ["txt", "ambos"]:
        etiqueta_tipo = (
            tipo_cliente if tipo_cliente and tipo_cliente != "Todos" else "General"
        )
        nombre_archivo = f"reportes_generados/reportes_estadisticos/Reporte_Estadistico_{etiqueta_tipo}_{timestamp}.txt"
        df_final_txt = df_final_export.copy()
        df_final_txt.columns = normalizar_nombres_columnas_visuales(
            df_final_txt.columns, "reportes_estadisticos"
        )
        leyenda_codigos = (
            "Leyenda: Canal (M=App Móvil, W=Web) | Tipo Cliente (N=Natural, J=Jurídico)"
        )

        with open(nombre_archivo, "w", encoding="utf-8") as f:
            f.write("REPORTE ESTADÍSTICO EJECUTIVO (CBO/CEO)\n")
            f.write(
                f"Día del reporte: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
            )
            f.write(f"{rango_fechas} | Tipo: {tipo_cliente} | Canal: {canal}\n")
            f.write(f"{leyenda_codigos}\n")
            f.write("-" * 85 + "\n\n")

            if df_final.empty:
                f.write("No se encontraron clientes con los criterios especificados.\n")
            else:
                f.write(df_final_txt.to_string(index=False))
                f.write("\n\n" + "-" * 80 + "\n")
                if "Saldo_Total" in df_final.columns:
                    f.write(
                        f"SALDO TOTAL: VES {formatear_monto_ves(saldo_total_general)}\n"
                    )

                titulo_rango_txt = f"Resumen de Operaciones ({rango_fechas})"
                f.write("\n")
                f.write(f"{titulo_rango_txt}\n")
                f.write("-" * len(titulo_rango_txt) + "\n")
                f.write(
                    f"TOTAL GENERAL DE INGRESOS (DEBE): VES {formatear_monto_ves(total_ingresos_periodo)}\n"
                )
                f.write(
                    f"TOTAL GENERAL DE EGRESOS (HABER): VES {formatear_monto_ves(total_egresos_periodo)}\n"
                )
                f.write(
                    f"BALANCE NETO DEL PERIODO: VES {formatear_monto_ves(balance_neto_periodo)}\n"
                )

                titulo_info_sistema_txt = "Información del Sistema"
                f.write(f"\n{titulo_info_sistema_txt}\n")
                f.write("-" * len(titulo_info_sistema_txt) + "\n")
                f.write(f"TOTAL CLIENTES ACTIVOS: {total_clientes_activos}\n")
                f.write(f"TOTAL CUENTAS ACTIVAS: {total_cuentas_activas}\n")
                f.write(f"TOTAL TARJETAS ACTIVAS: {total_tarjetas_activas}\n")
                f.write(
                    f"Onboarding por Canal - Portal Web: {onboarding_portal_web} clientes\n"
                )
                f.write(
                    f"Onboarding por Canal - App Móvil: {onboarding_app_movil} clientes\n"
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
            "Leyenda: Canal (M=App Móvil, W=Web) | Tipo Cliente (N=Natural, J=Jurídico)",
        ]
        titulo_rango = f"Resumen de Operaciones ({rango_fechas})"
        secciones_resumen_estadistico = [
            {
                "titulo": titulo_rango,
                "filas": [
                    (
                        "TOTAL GENERAL DE INGRESOS (DEBE)",
                        f"VES {formatear_monto_ves(total_ingresos_periodo)}",
                    ),
                    (
                        "TOTAL GENERAL DE EGRESOS (HABER)",
                        f"VES {formatear_monto_ves(total_egresos_periodo)}",
                    ),
                    (
                        "BALANCE NETO DEL PERIODO",
                        f"VES {formatear_monto_ves(balance_neto_periodo)}",
                    ),
                ],
            },
            {
                "titulo": "Información del Sistema",
                "filas": [
                    ("TOTAL CLIENTES ACTIVOS", total_clientes_activos),
                    ("TOTAL CUENTAS ACTIVAS", total_cuentas_activas),
                    ("TOTAL TARJETAS ACTIVAS", total_tarjetas_activas),
                    (
                        "Onboarding por Canal - Portal Web",
                        f"{onboarding_portal_web} clientes",
                    ),
                    (
                        "Onboarding por Canal - App Móvil",
                        f"{onboarding_app_movil} clientes",
                    ),
                ],
            },
        ]

        anchos_estadisticos = (11, 29, 11, 12, 12, 12, 18, 15, 15, 20)

        exportar_pdf(
            df_final_export,
            nombre_pdf,
            "reportes_estadisticos",
            metadata_lineas=metadata_pdf_estadistico,
            secciones_resumen=secciones_resumen_estadistico,
            saldo_total_texto=f"VES {formatear_monto_ves(saldo_total_general)}",
            anchos_columnas=anchos_estadisticos,
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
    total_movimientos_unicos = 0

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
            if "Referencia" in df_trabajo.columns:
                total_movimientos_unicos = int(df_trabajo["Referencia"].nunique())

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
            elif agrupar_por.lower() == "cliente":
                df_pivot = df_pivot.sort_values(by="ID_Cliente", ascending=True)
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
    columnas_monetarias_contables = [
        columna
        for columna in df_pivot.columns
        if columna
        in {
            "Ingresos",
            "Egresos",
            "Neto",
            "Comisiones",
            "Monto",
            "Saldo_Previo",
            "Saldo_Nuevo",
        }
        or columna.startswith("Mov_")
    ]
    df_pivot_export = formatear_columnas_monetarias(
        df_pivot, columnas_monetarias_contables
    )

    if usa_formato_v2 and not df_pivot.empty and "Ingresos" in df_pivot.columns:
        resumen_pdf_contable.append(
            (
                "TOTAL GENERAL DE INGRESOS (DEBE)",
                f"VES {formatear_monto_ves(df_pivot['Ingresos'].sum())}",
            )
        )
        resumen_pdf_contable.append(
            (
                "TOTAL GENERAL DE EGRESOS (HABER)",
                f"VES {formatear_monto_ves(df_pivot['Egresos'].sum())}",
            )
        )
        resumen_pdf_contable.append(
            (
                "BALANCE NETO DEL PERIODO",
                f"VES {formatear_monto_ves(df_pivot['Neto'].sum())}",
            )
        )
        resumen_pdf_contable.append(
            (
                "TOTAL COMISIONES",
                f"VES {formatear_monto_ves(df_pivot['Comisiones'].sum())}",
            )
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
                ("MOVIMIENTOS ANALIZADOS", total_movimientos_unicos)
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
        df_pivot_txt = df_pivot_export.copy()
        df_pivot_txt.columns = normalizar_nombres_columnas_visuales(
            df_pivot_txt.columns, "reportes_contables"
        )

        with open(nombre_archivo, "w", encoding="utf-8") as f:
            f.write("REPORTE CONTABLE DE INGRESOS Y EGRESOS\n")
            f.write(
                f"Día del reporte: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
            )
            f.write(f"Agrupado por: {agrupar_por.upper()}\n")
            f.write(f"{rango_fechas} | Estado: {estado_movimiento}\n")
            f.write("-" * 50 + "\n\n")
            f.write(df_pivot_txt.to_string(index=False))

            if usa_formato_v2 and not df_pivot.empty and "Ingresos" in df_pivot.columns:
                f.write("\n\n" + "-" * 50 + "\n")
                f.write(
                    f"TOTAL GENERAL DE INGRESOS (DEBE): VES {formatear_monto_ves(df_pivot['Ingresos'].sum())}\n"
                )
                f.write(
                    f"TOTAL GENERAL DE EGRESOS (HABER): VES {formatear_monto_ves(df_pivot['Egresos'].sum())}\n"
                )
                f.write(
                    f"BALANCE NETO DEL PERIODO: VES {formatear_monto_ves(df_pivot['Neto'].sum())}\n"
                )
                f.write(
                    f"TOTAL COMISIONES: VES {formatear_monto_ves(df_pivot['Comisiones'].sum())}\n"
                )
                columna_volumen = (
                    "Nro_Movimientos"
                    if "Nro_Movimientos" in df_pivot.columns
                    else "Volumen_Transacciones"
                    if "Volumen_Transacciones" in df_pivot.columns
                    else "Cantidad_Movimientos"
                )
                if columna_volumen in df_pivot.columns:
                    f.write(f"MOVIMIENTOS ANALIZADOS: {total_movimientos_unicos}\n")

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
        anchos_contables = construir_anchos_contables_pdf(
            df_pivot_export.columns.tolist()
        )
        exportar_pdf(
            df_pivot_export,
            nombre_pdf,
            "reportes_contables",
            resumen_tabla=resumen_pdf_contable,
            metadata_lineas=metadata_pdf_contable,
            anchos_columnas=anchos_contables,
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
        df_auditoria_txt = df_auditoria.copy()
        df_auditoria_txt.columns = normalizar_nombres_columnas_visuales(
            df_auditoria_txt.columns, "reportes_auditoria"
        )

        with open(nombre_archivo, "w", encoding="utf-8") as f:
            f.write("REPORTE DE AUDITORÍA: CLIENTES ELIMINADOS POR INACTIVIDAD\n")
            f.write(
                f"Día de ejecución: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
            )
            f.write("-" * 85 + "\n\n")
            f.write(df_auditoria_txt.to_string(index=False))

        print(f"[TXT OK] Reporte de auditoría generado en: {nombre_archivo}")

    if formato.lower() in ["pdf", "ambos"]:
        nombre_pdf = f"Reporte_Auditoria_Limpieza_{timestamp}.pdf"
        metadata_pdf_auditoria = [
            "Todos los registros hasta la fecha",
            f"Día de ejecución: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        ]
        exportar_pdf(
            df_auditoria,
            nombre_pdf,
            "reportes_auditoria",
            metadata_lineas=metadata_pdf_auditoria,
        )
