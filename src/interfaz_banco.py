import customtkinter as ctk
from main import obtener_datos_y_generar
from tkinter import messagebox

ctk.set_appearance_mode("dark")
ctk.set_default_color_theme("blue")

class InterfazBanco(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.title("USB Bank - Interfaz de Reportes")
        self.geometry("1000x620")
        self.minsize(950, 600)

        self.grid_columnconfigure(0, weight=0)
        self.grid_columnconfigure(1, weight=1)
        self.grid_rowconfigure(0, weight=1)

        self.seccion_activa = "estadistico"
        
        self.crear_panel_lateral()
        self.crear_panel_central()
        
        self.actualizar_estado_botones()

    def comando_generar_reporte(self, formato):
        """Recolecta los datos de la interfaz y ejecuta la generación en base de datos"""
        filtros = {
            'inicio': self.entry_inicio.get() if self.entry_inicio.get() else None,
            'fin': self.entry_fin.get() if self.entry_fin.get() else None,
            'tipo': self.combo_filtro.get(),
            'canal': 'Todos', 
            'agrupar_por': self.combo_filtro.get().lower() if self.seccion_activa == "contable" else 'cliente',
            'formato_deseado': formato
        }
        
        # Validar opciones para el reporte contable
        if self.seccion_activa == "contable" and filtros['agrupar_por'] not in ['cuenta', 'cliente', 'canal', 'tarjeta']:
            filtros['agrupar_por'] = 'cliente' # Default preventivo

        # ... dentro de comando_generar_reporte ...
        print(f"\n--- Solicitando Reporte {self.seccion_activa.upper()} en formato {formato.upper()} ---")
        obtener_datos_y_generar(self.seccion_activa, filtros)
        messagebox.showinfo("Éxito", f"Reporte {self.seccion_activa} ({formato.upper()}) generado correctamente.")
        
    def actualizar_estado_botones(self):
        color_activo = ("gray75", "gray25")
        
        # Resetear todos a transparente
        self.btn_clientes.configure(fg_color="transparent")
        self.btn_dinero.configure(fg_color="transparent")
        self.btn_auditoria.configure(fg_color="transparent")
        
        # Aplicar color al activo
        if self.seccion_activa == "estadistico":
            self.btn_clientes.configure(fg_color=color_activo)
        elif self.seccion_activa == "contable":
            self.btn_dinero.configure(fg_color=color_activo)
        elif self.seccion_activa == "auditoria":
            # Para auditoría mantenemos un tono rojo para destacar
            self.btn_auditoria.configure(fg_color=("#ffcccc", "#5C0000"))

    def mostrar_reporte_clientes(self):
        self.seccion_activa = "estadistico"
        self.titulo_seccion.configure(text="Generación de Reportes Estadísticos")
        self.combo_filtro.configure(state="normal", values=["Todos", "Natural", "Juridico"])
        self.combo_filtro.set("Todos")
        self.entry_inicio.configure(state="normal")
        self.entry_fin.configure(state="normal")
        self.actualizar_estado_botones()
        print("Navegación: Reporte Estadístico (Clientes)")

    def mostrar_reporte_dinero(self):
        self.seccion_activa = "contable"
        self.titulo_seccion.configure(text="Generación de Reporte Contable")
        self.combo_filtro.configure(state="normal", values=["Cliente", "Cuenta", "Canal", "Tarjeta"])
        self.combo_filtro.set("Cliente")
        self.entry_inicio.configure(state="normal")
        self.entry_fin.configure(state="normal")
        self.actualizar_estado_botones()
        print("Navegación: Reporte Contable (Dinero)")
    
    def mostrar_reporte_auditoria(self):
        self.seccion_activa = "auditoria"
        self.titulo_seccion.configure(text="Auditoría y Limpieza de Inactivos")
        self.combo_filtro.configure(values=["Ejecución Automática"], state="disabled")
        self.combo_filtro.set("Ejecución Automática")
        self.entry_inicio.configure(state="disabled")
        self.entry_fin.configure(state="disabled")
        self.actualizar_estado_botones()
        print("Navegación: Auditoría y Limpieza")
        
    def change_appearance_mode_event(self, new_appearence_mode: str):
        ctk.set_appearance_mode(new_appearence_mode)

    def crear_panel_lateral(self):
        self.frame_lateral = ctk.CTkFrame(self, width=240, corner_radius=0)
        self.frame_lateral.grid(row=0, column=0, sticky="nsew")
        self.frame_lateral.grid_propagate(False)

        self.frame_lateral.grid_rowconfigure(4, weight=1)

        titulo = ctk.CTkLabel(self.frame_lateral, text="USB Bank", font=ctk.CTkFont(size=26, weight="bold", family="Helvetica" ))
        titulo.grid(row=0, column=0, padx=20, pady=(30, 10))

        #subtitulo = ctk.CTkLabel(self.frame_lateral, text="Panel de Navegación", font=ctk.CTkFont(size=14))
        #subtitulo.grid(row=1, column=0, padx=20, pady=(0, 30))

        linea_divisoria = ctk.CTkFrame(self.frame_lateral, height=2, fg_color="gray30")
        linea_divisoria.grid(row=1, column=0, sticky="ew", padx=20, pady=(0, 20))
        
        self.btn_clientes = ctk.CTkButton(
            self.frame_lateral, text="Reporte Estadístico", command=self.mostrar_reporte_clientes,
            fg_color="transparent", text_color=("gray10", "gray90"), hover_color=("gray70", "gray30"),
            anchor="w", height=45, font=ctk.CTkFont(size=14, weight="bold")
        )
        self.btn_clientes.grid(row=2, column=0, padx=20, pady=5, sticky="ew")

        self.btn_dinero = ctk.CTkButton(
            self.frame_lateral, text="Reporte Contable", command=self.mostrar_reporte_dinero,
            fg_color="transparent", text_color=("gray10", "gray90"), hover_color=("gray70", "gray30"),
            anchor="w", height=45, font=ctk.CTkFont(size=14, weight="bold")
        )
        self.btn_dinero.grid(row=3, column=0, padx=20, pady=5, sticky="ew")

        self.btn_auditoria = ctk.CTkButton(
            self.frame_lateral, text="Limpieza / Auditoría", command=self.mostrar_reporte_auditoria,
            fg_color="transparent", text_color=("#8B0000", "#ff6666"), hover_color=("#ffcccc", "#5C0000"),
            anchor="w", height=45, font=ctk.CTkFont(size=14, weight="bold")
        )
        self.btn_auditoria.grid(row=4, column=0, padx=20, pady=5, sticky="nwe") # sticky="nwe" para que quede arriba del espacio sobrante

        # Switch de tema (abajo)
        self.appearance_mode_label = ctk.CTkLabel(self.frame_lateral, text="Modo Visual:", anchor="w")
        self.appearance_mode_label.grid(row=5, column=0, padx=20, pady=(10, 0), sticky="w")
        self.appearance_mode_optionemenu = ctk.CTkOptionMenu(
            self.frame_lateral, values=["Dark", "Light", "System"],
            command=self.change_appearance_mode_event
        )
        self.appearance_mode_optionemenu.grid(row=6, column=0, padx=20, pady=(10, 20), sticky="ew")

    def crear_panel_central(self):
        self.frame_central = ctk.CTkFrame(self, corner_radius=15, fg_color="transparent")
        self.frame_central.grid(row=0, column=1, padx=30, pady=30, sticky="nsew")

        self.frame_central.grid_columnconfigure(0, weight=1)

        # Header Dinámico
        self.titulo_seccion = ctk.CTkLabel(
            self.frame_central, text="Generación de Reportes Estadísticos", 
            font=ctk.CTkFont(size=28, weight="bold")
        )
        self.titulo_seccion.grid(row=0, column=0, sticky="w", pady=(10, 5))

        descripcion = ctk.CTkLabel(
            self.frame_central, text="Seleccione el rango de fechas, el filtro y genere su documento.", 
            font=ctk.CTkFont(size=14), text_color="gray"
        )
        descripcion.grid(row=1, column=0, sticky="w", pady=(0, 30))

        # Card de Formulario
        self.form_frame = ctk.CTkFrame(self.frame_central, corner_radius=15)
        self.form_frame.grid(row=2, column=0, sticky="nsew", padx=0, pady=0)
        self.form_frame.grid_columnconfigure((0, 1), weight=1)

        # Inputs de Fecha
        label_inicio = ctk.CTkLabel(self.form_frame, text="Fecha Inicio", font=ctk.CTkFont(weight="bold"))
        label_inicio.grid(row=0, column=0, padx=(30, 15), pady=(25, 5), sticky="w")

        self.entry_inicio = ctk.CTkEntry(self.form_frame, placeholder_text="Ej: 2020-01-01", height=45)
        self.entry_inicio.grid(row=1, column=0, padx=(30, 15), pady=(0, 15), sticky="ew")

        label_fin = ctk.CTkLabel(self.form_frame, text="Fecha Fin", font=ctk.CTkFont(weight="bold"))
        label_fin.grid(row=0, column=1, padx=(15, 30), pady=(25, 5), sticky="w")

        self.entry_fin = ctk.CTkEntry(self.form_frame, placeholder_text="Ej: 2026-12-31", height=45)
        self.entry_fin.grid(row=1, column=1, padx=(15, 30), pady=(0, 15), sticky="ew")

        # Filtro
        label_filtro = ctk.CTkLabel(self.form_frame, text="Filtro de Extracción", font=ctk.CTkFont(weight="bold"))
        label_filtro.grid(row=2, column=0, columnspan=2, padx=30, pady=(10, 5), sticky="w")

        self.combo_filtro = ctk.CTkComboBox(self.form_frame, values=["Todos", "Natural", "Juridico"], height=45)
        self.combo_filtro.set("Todos")
        self.combo_filtro.grid(row=3, column=0, columnspan=2, padx=30, pady=(0, 30), sticky="ew")

        # Botones de Acción Diferenciados (TXT / PDF)
        self.frame_botones = ctk.CTkFrame(self.frame_central, fg_color="transparent")
        self.frame_botones.grid(row=3, column=0, pady=(30, 0), sticky="e")

        self.btn_pdf = ctk.CTkButton(
            self.frame_botones, text="Exportar a PDF", 
            fg_color="#1f538d", hover_color="#14375e",
            width=160, height=45, font=ctk.CTkFont(size=14, weight="bold"),
            command=lambda: self.comando_generar_reporte("pdf")
        )
        self.btn_pdf.pack(side="right", padx=(10, 0))

        self.btn_txt = ctk.CTkButton(
            self.frame_botones, text="Descargar TXT", 
            fg_color="transparent", border_width=2,
            width=160, height=45, font=ctk.CTkFont(size=14, weight="bold"),
            command=lambda: self.comando_generar_reporte("txt")
        )
        self.btn_txt.pack(side="right", padx=10)

if __name__ == "__main__":
    app = InterfazBanco()
    app.mainloop()