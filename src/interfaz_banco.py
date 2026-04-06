import customtkinter as ctk
from tkinter import ttk


# Funciones vacías
def comando_generar_txt():
    print("Botón TXT presionado")


def comando_generar_pdf():
    print("Botón PDF presionado")


def mostrar_reporte_clientes():
    print("Navegación: Reporte Estadístico (Clientes)")


def mostrar_reporte_dinero():
    print("Navegación: Reporte Contable (Dinero)")


# Configuración principal
ctk.set_appearance_mode("dark")
ctk.set_default_color_theme("blue")


class InterfazBanco(ctk.CTk):
    def __init__(self):
        super().__init__()

        self.title("USB Bank - Interfaz de Reportes")
        self.geometry("1000x600")
        self.minsize(900, 550)

        # Layout general: 2 columnas
        self.grid_columnconfigure(0, weight=0)  # panel lateral
        self.grid_columnconfigure(1, weight=1)  # panel central
        self.grid_rowconfigure(0, weight=1)

        self.crear_panel_lateral()
        self.crear_panel_central()

    def crear_panel_lateral(self):
        self.frame_lateral = ctk.CTkFrame(self, width=250, corner_radius=0)
        self.frame_lateral.grid(row=0, column=0, sticky="nsew")
        self.frame_lateral.grid_propagate(False)

        self.frame_lateral.grid_rowconfigure(0, weight=0)
        self.frame_lateral.grid_rowconfigure(1, weight=0)
        self.frame_lateral.grid_rowconfigure(2, weight=0)
        self.frame_lateral.grid_rowconfigure(3, weight=1)

        titulo = ctk.CTkLabel(
            self.frame_lateral,
            text="USB Bank",
            font=ctk.CTkFont(size=24, weight="bold")
        )
        titulo.grid(row=0, column=0, padx=20, pady=(30, 20))

        subtitulo = ctk.CTkLabel(
            self.frame_lateral,
            text="Panel de Navegación",
            font=ctk.CTkFont(size=14)
        )
        subtitulo.grid(row=1, column=0, padx=20, pady=(0, 30))

        self.btn_clientes = ctk.CTkButton(
            self.frame_lateral,
            text="Reporte Estadístico\n(Clientes)",
            command=mostrar_reporte_clientes,
            width=190,
            height=60,
            font=ctk.CTkFont(size=15, weight="bold")
        )
        self.btn_clientes.grid(row=2, column=0, padx=20, pady=10)

        self.btn_dinero = ctk.CTkButton(
            self.frame_lateral,
            text="Reporte Contable\n(Dinero)",
            command=mostrar_reporte_dinero,
            width=190,
            height=60,
            font=ctk.CTkFont(size=15, weight="bold")
        )
        self.btn_dinero.grid(row=3, column=0, padx=20, pady=10, sticky="n")

    def crear_panel_central(self):
        self.frame_central = ctk.CTkFrame(self, corner_radius=15)
        self.frame_central.grid(row=0, column=1, padx=20, pady=20, sticky="nsew")

        self.frame_central.grid_columnconfigure(0, weight=1)
        self.frame_central.grid_columnconfigure(1, weight=1)

        titulo = ctk.CTkLabel(
            self.frame_central,
            text="Generación de Reportes",
            font=ctk.CTkFont(size=26, weight="bold")
        )
        titulo.grid(row=0, column=0, columnspan=2, padx=30, pady=(30, 10), sticky="w")

        descripcion = ctk.CTkLabel(
            self.frame_central,
            text="Seleccione el rango de fechas, el filtro y el formato de salida.",
            font=ctk.CTkFont(size=14)
        )
        descripcion.grid(row=1, column=0, columnspan=2, padx=30, pady=(0, 25), sticky="w")

        # Fecha inicio
        label_inicio = ctk.CTkLabel(
            self.frame_central,
            text="Fecha Inicio",
            font=ctk.CTkFont(size=15, weight="bold")
        )
        label_inicio.grid(row=2, column=0, padx=(30, 15), pady=(10, 5), sticky="w")

        self.entry_inicio = ctk.CTkEntry(
            self.frame_central,
            placeholder_text="Ej: 2026-01-01",
            height=40
        )
        self.entry_inicio.grid(row=3, column=0, padx=(30, 15), pady=(0, 15), sticky="ew")

        # Fecha fin
        label_fin = ctk.CTkLabel(
            self.frame_central,
            text="Fecha Fin",
            font=ctk.CTkFont(size=15, weight="bold")
        )
        label_fin.grid(row=2, column=1, padx=(15, 30), pady=(10, 5), sticky="w")

        self.entry_fin = ctk.CTkEntry(
            self.frame_central,
            placeholder_text="Ej: 2026-12-31",
            height=40
        )
        self.entry_fin.grid(row=3, column=1, padx=(15, 30), pady=(0, 15), sticky="ew")

        # Filtro
        label_filtro = ctk.CTkLabel(
            self.frame_central,
            text="Filtro",
            font=ctk.CTkFont(size=15, weight="bold")
        )
        label_filtro.grid(row=4, column=0, columnspan=2, padx=30, pady=(10, 5), sticky="w")

        self.combo_filtro = ctk.CTkComboBox(
            self.frame_central,
            values=["Todos", "Natural", "Jurídico", "Canal Web"],
            height=40
        )
        self.combo_filtro.set("Todos")
        self.combo_filtro.grid(row=5, column=0, columnspan=2, padx=30, pady=(0, 25), sticky="ew")

        # Botones inferiores
        self.frame_botones = ctk.CTkFrame(self.frame_central, fg_color="transparent")
        self.frame_botones.grid(row=6, column=0, columnspan=2, padx=30, pady=(20, 30), sticky="e")

        self.btn_txt = ctk.CTkButton(
            self.frame_botones,
            text="Generar TXT",
            command=comando_generar_txt,
            width=140,
            height=42
        )
        self.btn_txt.pack(side="left", padx=10)

        self.btn_pdf = ctk.CTkButton(
            self.frame_botones,
            text="Generar PDF",
            command=comando_generar_pdf,
            width=140,
            height=42
        )
        self.btn_pdf.pack(side="left", padx=10)


if __name__ == "__main__":
    app = InterfazBanco()
    app.mainloop()