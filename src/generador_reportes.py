from creador_dir_reportes import creacion_de_carpeta_reportes
import pandas as pd
from fpdf import FPDF # Importación corregida para fpdf2
import os
from datetime import datetime

##IMPORTANTE: 
##Debe tener el modulo virtualenv para que el programa funcione bien, ademas de activar el venv antes de ejecutar
#el codigo, corriendo el script 'c:\users\usuario\myenv\Scripts\activate'

#Aqui creamos los directorios necesarios para guardar los reportes, si es que no existen 
creacion_de_carpeta_reportes('reportes_generados')
carpetas_reportes = ['reportes_estadisticos', 'reportes_contables', 'reportes_auditoria']
ruta = 'reportes_generados'
for carpeta in carpetas_reportes:
    ruta_completa = os.path.join(ruta, carpeta)
    os.makedirs(ruta_completa, exist_ok=True)
print('Creacion de las carpetas de reportes completada.')

#Función exportar_pdf, que convierte los reportes de txt a pdf
def exportar_pdf(datos, nombre_reporte, subcarpeta):
    pdf = FPDF()
    pdf.add_page()
    
    # Encabezado del pdf
    pdf.set_font("helvetica", style="B", size=16)
    pdf.cell(0, 10, "USB Bank - Reporte Oficial", align="C", new_x="LMARGIN", new_y="NEXT")
    
    # Fecha del pdf 
    pdf.set_font("helvetica", style="I", size=10)
    fecha_actual = datetime.now().strftime("%d/%m/%Y %H:%M:%S")
    pdf.cell(0, 10, f"Fecha de emisión: {fecha_actual}", align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(5) 
    
    
    columnas = [str(col) for col in datos.columns.tolist()]
    filas = datos.astype(str).values.tolist()
    
    # dibujo la tabla especificada
    pdf.set_font("helvetica", size=9)
    with pdf.table(text_align="CENTER") as table:
        encabezado = table.row()
        for col_name in columnas:
            pdf.set_font(style="B") 
            encabezado.cell(col_name)
        
        pdf.set_font(style="") 
        for fila_datos in filas:
            fila = table.row()
            for item in fila_datos:
                fila.cell(item)
                
    # Guardo el archivo
    if not nombre_reporte.endswith('.pdf'):
        nombre_reporte += '.pdf'
        
    ruta_destino = os.path.join('reportes_generados', subcarpeta, nombre_reporte)
    pdf.output(ruta_destino)
    print(f"[PDF OK] Reporte guardado en: {ruta_destino}")

#generador_reportes_estadisticos genera los reportes estadisticos con los requerimientos solicitados
#la cual genera un txt y un pdf como reportes 
def generador_reportes_estadisticos(df_clientes, fecha_inicio=None, fecha_fin=None, tipo_cliente=None, canal=None):
    print("¡Llamada al integrador detectada!")
    if df_clientes.empty:
        print("[AVISO] No hay datos en la base de datos para generar este reporte estadístico.")

    clientes_filtrado = df_clientes.copy()

    if 'Fecha_Registro' in clientes_filtrado.columns:
        clientes_filtrado['Fecha_Registro'] = pd.to_datetime(clientes_filtrado['Fecha_Registro'])
        
        if fecha_inicio and fecha_fin: 
            fecha_inicio = pd.to_datetime(fecha_inicio)
            fecha_fin = pd.to_datetime(fecha_fin)
            clientes_filtrado = clientes_filtrado[(clientes_filtrado['Fecha_Registro'] >= fecha_inicio) &
                                                    (clientes_filtrado['Fecha_Registro'] <= fecha_fin)]
    if tipo_cliente and tipo_cliente != "Todos": 
        clientes_filtrado = clientes_filtrado[clientes_filtrado['Tipo_Cliente'] == tipo_cliente]
        
    if canal and canal != "Todos": 
        clientes_filtrado = clientes_filtrado[clientes_filtrado['Canal_Afiliacion'] == canal]
    
    columnas_deseadas = ['ID_Cliente', 'Nombre', 'Tipo_Cliente', 'Total_Productos', 'Saldo_Total']
    columnas_reporte = [col for col in columnas_deseadas if col in clientes_filtrado.columns]
    
    df_final = clientes_filtrado[columnas_reporte]

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")
    nombre_archivo = f"reportes_generados/reportes_estadisticos/Reporte_CBO_CEO_{timestamp}.txt"

    with open(nombre_archivo, 'w', encoding='utf-8') as f:
        f.write("REPORTE ESTADISTICO EJECUTIVO (CBO/CEO)\n")
        f.write(f"Dia del reporte: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"Fechas: {fecha_inicio} a {fecha_fin} | Tipo: {tipo_cliente} | Canal: {canal}\n")
        f.write("-" * 80 + "\n\n")

        if df_final.empty:
            f.write("No se encontraron clientes con los criterios especificados.\n")
        else: 
            f.write(df_final.to_string(index=False))
            f.write("\n\n" + "-" * 80 + "\n")
            if 'Saldo_Total' in df_final.columns:
                f.write(f"SALDO TOTAL: ${df_final['Saldo_Total'].astype(float).sum():,.2f}\n")

    print(f"[TXT OK] Reporte estadístico generado en: {nombre_archivo}")

    #genero el pdf en cuestion
    etiqueta_tipo = tipo_cliente if tipo_cliente and tipo_cliente != "Todos" else "General"
    nombre_pdf = f"Reporte_Estadistico_{etiqueta_tipo}_{timestamp}.pdf"
    exportar_pdf(df_final, nombre_pdf, 'reportes_estadisticos')

#hace lo mismo que generador_reportes_estadisticos, pero con reportes contables
def generador_reportes_contables(df_movimientos, agrupar_por: str):
    if df_movimientos.empty:
        print("[AVISO] No hay datos de movimientos para generar este reporte contable.")
        return
    
    columnas_validas = {'cuenta': 'Cuenta', 'cliente': 'ID_Cliente', 'canal': 'Canal_Tx', 'tarjeta': 'Tarjeta'}

    if agrupar_por.lower() not in columnas_validas:
        print("Error: debe agruparse por 'cuenta', 'cliente', 'canal', 'tarjeta'")
        return 
    
    columna_agrupacion = columnas_validas[agrupar_por.lower()]

    if columna_agrupacion not in df_movimientos.columns or 'Monto' not in df_movimientos.columns or 'Tipo_Movimiento' not in df_movimientos.columns:
        print(f"[ERROR] Faltan columnas en los datos para agrupar por {agrupar_por}.")
        return
    
    df_pivot = pd.pivot_table(df_movimientos, values='Monto', index=columna_agrupacion, 
                                columns='Tipo_Movimiento', aggfunc='sum', fill_value=0).reset_index()
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    nombre_archivo = f"reportes_generados/reportes_contables/Saldos_Por_{agrupar_por.capitalize()}_{timestamp}.txt"

    with open(nombre_archivo, 'w', encoding='utf-8') as f:
        f.write("REPORTE CONTABLE DE INGRESOS Y EGRESOS\n")
        f.write(f"Agrupado por: {agrupar_por.upper()}\n")
        f.write("-" * 50 + "\n\n")
        f.write(df_pivot.to_string(index=False))
        
    print(f"[TXT OK] Reporte contable generado en: {nombre_archivo}")

    #genera el PDF para el reporte contable
    nombre_pdf = f"Saldos_Por_{agrupar_por}_{timestamp}.pdf"
    exportar_pdf(df_pivot, nombre_pdf, 'reportes_contables')
    
# Esta funcion hace el reporte de clientes eliminados por inactividad
def generador_reportes_auditoria(df_auditoria):
    if df_auditoria.empty:
        print("[AVISO] No hay clientes eliminados registrados en la auditoría.")
        return

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    nombre_archivo = f"reportes_generados/reportes_auditoria/Auditoria_Limpieza_{timestamp}.txt"

    with open(nombre_archivo, 'w', encoding='utf-8') as f:
        f.write("REPORTE DE AUDITORÍA: CLIENTES ELIMINADOS POR INACTIVIDAD\n")
        f.write(f"Día de ejecución: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write("-" * 80 + "\n\n")
        f.write(df_auditoria.to_string(index=False))
        
    print(f"[TXT OK] Reporte de auditoría generado en: {nombre_archivo}")

    nombre_pdf = f"Auditoria_Limpieza_{timestamp}.pdf"
    exportar_pdf(df_auditoria, nombre_pdf, 'reportes_auditoria')