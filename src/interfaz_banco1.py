import customtkinter as ctk
from main import obtener_datos_y_generar # <-- Importamos la conexión a la BD

ctk.set_appearance_mode("dark")
ctk.set_default_color_theme("blue")

class InterfazBanco(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.title("USB Bank - Interfaz de Reportes")
        self.geometry("1000x600")
        self.minsize(900, 550)

        self.grid_columnconfigure(0, weight=0)
        self.grid_columnconfigure(1, weight=1)
        self.grid_rowconfigure(0, weight=1)

        self.seccion_activa = "estadistico"
        
        self.crear_panel_lateral()
        self.crear_panel_central()

    def comando_generar_reporte(self):
        """Recolecta los datos de la interfaz y ejecuta la generación en base de datos"""
        filtros = {
            'inicio': self.entry_inicio.get() if self.entry_inicio.get() else None,
            'fin': self.entry_fin.get() if self.entry_fin.get() else None,
            'tipo': self.combo_filtro.get(),
            'canal': 'Todos', 
            'agrupar_por': self.combo_filtro.get().lower() if self.seccion_activa == "contable" else 'cliente'
        }
        
        # Validar opciones para el reporte contable
        if self.seccion_activa == "contable" and filtros['agrupar_por'] not in ['cuenta', 'cliente', 'canal', 'tarjeta']:
            filtros['agrupar_por'] = 'cliente' # Default preventivo

        from tkinter import messagebox
        # ... dentro de comando_generar_reporte ...
        print(f"\n--- Solicitando Reporte {self.seccion_activa.upper()} ---")
        obtener_datos_y_generar(self.seccion_activa, filtros)
        messagebox.showinfo("Éxito", f"Reporte {self.seccion_activa} generado correctamente.")

    def mostrar_reporte_clientes(self):
        self.seccion_activa = "estadistico"
        self.combo_filtro.configure(state="normal", values=["Todos", "Natural", "Juridico"])
        self.combo_filtro.set("Todos")
        self.entry_inicio.configure(state="normal")
        self.entry_fin.configure(state="normal")
        print("Navegación: Reporte Estadístico (Clientes)")

    def mostrar_reporte_dinero(self):
        self.seccion_activa = "contable"
        self.combo_filtro.configure(state="normal", values=["Cliente", "Cuenta", "Canal", "Tarjeta"])
        self.combo_filtro.set("Cliente")
        self.entry_inicio.configure(state="normal")
        self.entry_fin.configure(state="normal")
        print("Navegación: Reporte Contable (Dinero)")
    
    def mostrar_reporte_auditoria(self):
        self.seccion_activa = "auditoria"
        self.combo_filtro.configure(values=["Ejecución Automática"], state="disabled")
        self.combo_filtro.set("Ejecución Automática")
        self.entry_inicio.configure(state="disabled")
        self.entry_fin.configure(state="disabled")
        print("Navegación: Auditoría y Limpieza")

    def crear_panel_lateral(self):
        self.frame_lateral = ctk.CTkFrame(self, width=250, corner_radius=0)
        self.frame_lateral.grid(row=0, column=0, sticky="nsew")
        self.frame_lateral.grid_propagate(False)

        self.frame_lateral.grid_rowconfigure(0, weight=0)
        self.frame_lateral.grid_rowconfigure(1, weight=0)
        self.frame_lateral.grid_rowconfigure(2, weight=0)
        self.frame_lateral.grid_rowconfigure(3, weight=1)

        titulo = ctk.CTkLabel(self.frame_lateral, text="USB Bank", font=ctk.CTkFont(size=24, weight="bold"))
        titulo.grid(row=0, column=0, padx=20, pady=(30, 20))

        subtitulo = ctk.CTkLabel(self.frame_lateral, text="Panel de Navegación", font=ctk.CTkFont(size=14))
        subtitulo.grid(row=1, column=0, padx=20, pady=(0, 30))

        self.btn_clientes = ctk.CTkButton(
            self.frame_lateral, text="Reporte Estadístico\n(Clientes)", command=self.mostrar_reporte_clientes,
            width=190, height=60, font=ctk.CTkFont(size=15, weight="bold")
        )
        self.btn_clientes.grid(row=2, column=0, padx=20, pady=10)

        self.btn_dinero = ctk.CTkButton(
            self.frame_lateral, text="Reporte Contable\n(Dinero)", command=self.mostrar_reporte_dinero,
            width=190, height=60, font=ctk.CTkFont(size=15, weight="bold")
        )
        self.btn_dinero.grid(row=3, column=0, padx=20, pady=10, sticky="n")
        # Debajo de self.btn_dinero...
        self.frame_lateral.grid_rowconfigure(4, weight=1)

        self.btn_auditoria = ctk.CTkButton(
            self.frame_lateral, text="Limpieza / Auditoría\n(Seguridad)", command=self.mostrar_reporte_auditoria,
            width=190, height=60, font=ctk.CTkFont(size=15, weight="bold"), fg_color="#8B0000", hover_color="#5C0000" # Rojo para indicar peligro/borrado
        )
        self.btn_auditoria.grid(row=4, column=0, padx=20, pady=10, sticky="n")

    def crear_panel_central(self):
        self.frame_central = ctk.CTkFrame(self, corner_radius=15)
        self.frame_central.grid(row=0, column=1, padx=20, pady=20, sticky="nsew")

        self.frame_central.grid_columnconfigure(0, weight=1)
        self.frame_central.grid_columnconfigure(1, weight=1)

        titulo = ctk.CTkLabel(self.frame_central, text="Generación de Reportes", font=ctk.CTkFont(size=26, weight="bold"))
        titulo.grid(row=0, column=0, columnspan=2, padx=30, pady=(30, 10), sticky="w")

        descripcion = ctk.CTkLabel(self.frame_central, text="Seleccione el rango de fechas, el filtro y genere su documento.", font=ctk.CTkFont(size=14))
        descripcion.grid(row=1, column=0, columnspan=2, padx=30, pady=(0, 25), sticky="w")

        label_inicio = ctk.CTkLabel(self.frame_central, text="Fecha Inicio", font=ctk.CTkFont(size=15, weight="bold"))
        label_inicio.grid(row=2, column=0, padx=(30, 15), pady=(10, 5), sticky="w")

        self.entry_inicio = ctk.CTkEntry(self.frame_central, placeholder_text="Ej: 2020-01-01", height=40)
        self.entry_inicio.grid(row=3, column=0, padx=(30, 15), pady=(0, 15), sticky="ew")

        label_fin = ctk.CTkLabel(self.frame_central, text="Fecha Fin", font=ctk.CTkFont(size=15, weight="bold"))
        label_fin.grid(row=2, column=1, padx=(15, 30), pady=(10, 5), sticky="w")

        self.entry_fin = ctk.CTkEntry(self.frame_central, placeholder_text="Ej: 2026-12-31", height=40)
        self.entry_fin.grid(row=3, column=1, padx=(15, 30), pady=(0, 15), sticky="ew")

        label_filtro = ctk.CTkLabel(self.frame_central, text="Filtro de Extracción", font=ctk.CTkFont(size=15, weight="bold"))
        label_filtro.grid(row=4, column=0, columnspan=2, padx=30, pady=(10, 5), sticky="w")

        self.combo_filtro = ctk.CTkComboBox(self.frame_central, values=["Todos", "Natural", "Juridico"], height=40)
        self.combo_filtro.set("Todos")
        self.combo_filtro.grid(row=5, column=0, columnspan=2, padx=30, pady=(0, 25), sticky="ew")

        self.frame_botones = ctk.CTkFrame(self.frame_central, fg_color="transparent")
        self.frame_botones.grid(row=6, column=0, columnspan=2, padx=30, pady=(20, 30), sticky="e")

        self.btn_generar = ctk.CTkButton(
            self.frame_botones, text="EJECUTAR REPORTE", command=self.comando_generar_reporte,
            width=200, height=50, font=ctk.CTkFont(size=15, weight="bold")
        )
        self.btn_generar.pack(side="left", padx=10)

if __name__ == "__main__":
    app = InterfazBanco()
    app.mainloop()