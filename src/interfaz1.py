import customtkinter as ctk
from tkinter import messagebox

# Configuración inicial
ctk.set_appearance_mode("dark")
ctk.set_default_color_theme("blue")

class InterfazBanco(ctk.CTk):
    def __init__(self):
        super().__init__()

        # Configuración de ventana
        self.title("USB Bank - Sistema de Reportes")
        self.geometry("1000x620")
        self.minsize(950, 600)

        # Configuración de Layout (Grid 1x2)
        self.grid_columnconfigure(1, weight=1)
        self.grid_rowconfigure(0, weight=1)

        # Variables de estado
        self.seccion_activa = "clientes"

        self.crear_panel_lateral()
        self.crear_panel_central()

    def crear_panel_lateral(self):
        """Crea la barra de navegación lateral."""
        self.sidebar = ctk.CTkFrame(self, width=240, corner_radius=0)
        self.sidebar.grid(row=0, column=0, sticky="nsew")
        self.sidebar.grid_rowconfigure(4, weight=1) # Espaciador

        # Logo/Título
        self.logo_label = ctk.CTkLabel(
            self.sidebar, 
            text="USB Bank", 
            font=ctk.CTkFont(size=26, weight="bold", family="Helvetica")
        )
        self.logo_label.grid(row=0, column=0, padx=20, pady=(30, 10))
        
        self.linea_divisoria = ctk.CTkFrame(self.sidebar, height=2, fg_color="gray30")
        self.linea_divisoria.grid(row=1, column=0, sticky="ew", padx=20, pady=(0, 20))

        # Botones de navegación
        self.btn_clientes = ctk.CTkButton(
            self.sidebar, text="Reporte Clientes",
            fg_color="transparent", text_color=("gray10", "gray90"),
            hover_color=("gray70", "gray30"),
            anchor="w", height=45,
            command=lambda: self.cambiar_seccion("clientes")
        )
        self.btn_clientes.grid(row=2, column=0, padx=20, pady=5, sticky="ew")

        self.btn_dinero = ctk.CTkButton(
            self.sidebar, text="Reporte Contable",
            fg_color="transparent", text_color=("gray10", "gray90"),
            hover_color=("gray70", "gray30"),
            anchor="w", height=45,
            command=lambda: self.cambiar_seccion("contable")
        )
        self.btn_dinero.grid(row=3, column=0, padx=20, pady=5, sticky="ew")

        # Switch de tema
        self.appearance_mode_label = ctk.CTkLabel(self.sidebar, text="Modo Visual:", anchor="w")
        self.appearance_mode_label.grid(row=5, column=0, padx=20, pady=(10, 0))
        self.appearance_mode_optionemenu = ctk.CTkOptionMenu(
            self.sidebar, values=["Dark", "Light", "System"],
            command=self.change_appearance_mode_event
        )
        self.appearance_mode_optionemenu.grid(row=6, column=0, padx=20, pady=(10, 20))

    def crear_panel_central(self):
        """Contenedor principal de formularios."""
        self.main_view = ctk.CTkFrame(self, corner_radius=20, fg_color="transparent")
        self.main_view.grid(row=0, column=1, padx=30, pady=30, sticky="nsew")
        self.main_view.grid_columnconfigure(0, weight=1)

        # Header
        self.titulo_seccion = ctk.CTkLabel(
            self.main_view, text="Generación de Reportes Estadísticos",
            font=ctk.CTkFont(size=28, weight="bold")
        )
        self.titulo_seccion.grid(row=0, column=0, sticky="w", pady=(10, 5))

        self.sub_text = ctk.CTkLabel(
            self.main_view, text="Configure los parámetros para filtrar la base de datos de clientes.",
            font=ctk.CTkFont(size=14), text_color="gray"
        )
        self.sub_text.grid(row=1, column=0, sticky="w", pady=(0, 30))

        # Card de Formulario
        self.form_frame = ctk.CTkFrame(self.main_view, corner_radius=15)
        self.form_frame.grid(row=2, column=0, sticky="nsew", padx=0, pady=0)
        self.form_frame.grid_columnconfigure((0, 1), weight=1)

        # Inputs de Fecha
        self.crear_input(self.form_frame, "Fecha de Inicio", "Ej: 2026-01-01", 0, 0)
        self.crear_input(self.form_frame, "Fecha de Finalización", "Ej: 2026-12-31", 0, 1)

        # Filtros
        self.label_filtro = ctk.CTkLabel(self.form_frame, text="Categoría de Filtro", font=ctk.CTkFont(weight="bold"))
        self.label_filtro.grid(row=2, column=0, columnspan=2, padx=30, pady=(20, 5), sticky="w")
        
        self.combo_filtro = ctk.CTkComboBox(
            self.form_frame, values=["Todos los Clientes", "Persona Natural", "Persona Jurídica", "Canal Web"],
            height=45, fg_color="gray10"
        )
        self.combo_filtro.grid(row=3, column=0, columnspan=2, padx=30, pady=(0, 30), sticky="ew")

        # Botones de Acción
        self.btn_frame = ctk.CTkFrame(self.main_view, fg_color="transparent")
        self.btn_frame.grid(row=3, column=0, sticky="e", pady=30)

        self.btn_pdf = ctk.CTkButton(
            self.btn_frame, text="Exportar a PDF", 
            image=None, compound="left",
            fg_color="#1f538d", hover_color="#14375e",
            width=160, height=45, command=self.generar_pdf
        )
        self.btn_pdf.pack(side="right", padx=(10, 0))

        self.btn_txt = ctk.CTkButton(
            self.btn_frame, text="Descargar TXT", 
            fg_color="transparent", border_width=2,
            width=160, height=45, command=self.generar_txt
        )
        self.btn_txt.pack(side="right", padx=10)

    def crear_input(self, master, texto, placeholder, row, col):
        """Helper para crear etiquetas y entries rápidamente."""
        lbl = ctk.CTkLabel(master, text=texto, font=ctk.CTkFont(weight="bold"))
        lbl.grid(row=row, column=col, padx=30, pady=(25, 5), sticky="w")
        entry = ctk.CTkEntry(master, placeholder_text=placeholder, height=45)
        entry.grid(row=row+1, column=col, padx=30, pady=(0, 10), sticky="ew")
        return entry

    # --- Lógica de la interfaz ---
    def cambiar_seccion(self, seccion):
        self.seccion_activa = seccion
        if seccion == "clientes":
            self.titulo_seccion.configure(text="Generación de Reportes Estadísticos")
            self.btn_clientes.configure(fg_color=("gray75", "gray25"))
            self.btn_dinero.configure(fg_color="transparent")
        else:
            self.titulo_seccion.configure(text="Generación de Reporte Contable")
            self.btn_dinero.configure(fg_color=("gray75", "gray25"))
            self.btn_clientes.configure(fg_color="transparent")

    def change_appearance_mode_event(self, new_appearance_mode: str):
        ctk.set_appearance_mode(new_appearance_mode)

    def generar_pdf(self):
        messagebox.showinfo("USB Bank", "Reporte PDF generado exitosamente.")

    def generar_txt(self):
        print("Generando archivo TXT...")

if __name__ == "__main__":
    app = InterfazBanco()
    app.mainloop()