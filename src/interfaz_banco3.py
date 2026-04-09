import customtkinter as ctk
from tkinter import messagebox

# 🎨 PALETAS DE COLORES (Refinadas para legibilidad)
COLORS_DARK = {
    "bg": "#0F1117",
    "sidebar": "#161922",
    "card": "#1A1D2B",
    "card_border": "#252938",
    "text_primary": "#E8EAEF",
    "text_secondary": "#94A3B8",
    "accent": "#3B82F6",
    "accent_hover": "#2563EB",
    "btn_neutral": "#252938",
    "btn_neutral_hover": "#2E3348",
}

COLORS_LIGHT = {
    "bg": "#F8FAFC",          # Blanco "Ice" suave
    "sidebar": "#FFFFFF",     # Blanco puro para contraste
    "card": "#FFFFFF",
    "card_border": "#E2E8F0", # Gris seda
    "text_primary": "#1E293B",# Carbón azulado (No es negro puro)
    "text_secondary": "#64748B",# Gris medio
    "accent": "#2563EB",      # Azul corporativo
    "accent_hover": "#1D4ED8",
    "btn_neutral": "#F1F5F9", # Botón suave
    "btn_neutral_hover": "#E2E8F0",
}

class InterfazBanco(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.title("USB Bank — Gestión de Reportes")
        self.geometry("1100x700")
        
        self.seccion_activa = "estadistico"
        self.current_colors = COLORS_DARK.copy()
        ctk.set_appearance_mode("dark")

        # Layout Principal
        self.grid_columnconfigure(0, weight=0)
        self.grid_columnconfigure(1, weight=1)
        self.grid_rowconfigure(0, weight=1)

        self.crear_panel_lateral()
        self.crear_panel_central()
        self.update_ui_colors()

    def lerp_color(self, c1, c2, t):
        """Mezcla dos colores hex suavemente"""
        def h2r(h): return [int(h.lstrip('#')[i:i+2], 16) for i in (0, 2, 4)]
        r1, g1, b1 = h2r(c1)
        r2, g2, b2 = h2r(c2)
        r, g, b = [int(v1 + (v2 - v1) * t) for v1, v2 in zip([r1, g1, b1], [r2, g2, b2])]
        return f'#{r:02x}{g:02x}{b:02x}'

    def animate_transition(self, target_palette, steps=10):
        """Transición visual de colores"""
        start_palette = self.current_colors.copy()
        for i in range(1, steps + 1):
            t = i / steps
            temp_colors = {k: self.lerp_color(start_palette[k], target_palette[k], t) 
                           for k in target_palette if k in start_palette}
            self.current_colors.update(temp_colors)
            self.update_ui_colors(is_partial=True)
            self.update_idletasks()
            self.after(5)
        self.current_colors = target_palette.copy()
        self.update_ui_colors()

    def update_ui_colors(self, is_partial=False):
        c = self.current_colors
        self.configure(fg_color=c["bg"])
        self.frame_lateral.configure(fg_color=c["sidebar"])
        self.frame_central.configure(fg_color=c["bg"])
        self.form_frame.configure(fg_color=c["card"], border_color=c["card_border"])

        if not is_partial:
            self.logo_label.configure(text_color=c["text_primary"])
            self.sub_label.configure(text_color=c["text_secondary"])
            self.tema_label.configure(text_color=c["text_secondary"])
            self.titulo_seccion.configure(text_color=c["text_primary"])
            self.desc_label.configure(text_color=c["text_secondary"])
            self.divider.configure(fg_color=c["card_border"])
            
            for lbl in [self.lbl_inicio, self.lbl_fin, self.lbl_filtro]:
                lbl.configure(text_color=c["text_secondary"])

            # Ajuste de inputs para que no sean negros en modo claro
            input_bg = c["bg"] if ctk.get_appearance_mode() == "Dark" else "#FFFFFF"
            
            self.entry_inicio.configure(fg_color=input_bg, border_color=c["card_border"], text_color=c["text_primary"])
            self.entry_fin.configure(fg_color=input_bg, border_color=c["card_border"], text_color=c["text_primary"])
            self.combo_filtro.configure(fg_color=input_bg, border_color=c["card_border"], text_color=c["text_primary"])
            
            self.btn_pdf.configure(fg_color=c["accent"], hover_color=c["accent_hover"])
            self.btn_txt.configure(fg_color=c["btn_neutral"], hover_color=c["btn_neutral_hover"], text_color=c["text_primary"])
            self.appearance_mode_menu.configure(fg_color=c["btn_neutral"], button_color=c["btn_neutral"], text_color=c["text_primary"])
            self.actualizar_estado_botones()

    def change_appearance_mode_event(self, new_mode):
        target = COLORS_LIGHT if new_mode.lower() == "light" else COLORS_DARK
        ctk.set_appearance_mode(new_mode)
        self.animate_transition(target)

    def actualizar_estado_botones(self):
        c = self.current_colors
        for btn in [self.btn_clientes, self.btn_dinero, self.btn_auditoria]:
            btn.configure(fg_color="transparent", text_color=c["text_secondary"])
        
        mapping = {"estadistico": self.btn_clientes, "contable": self.btn_dinero}
        if self.seccion_activa in mapping:
            mapping[self.seccion_activa].configure(fg_color=c["btn_neutral"], text_color=c["text_primary"])
        elif self.seccion_activa == "auditoria":
            is_light = ctk.get_appearance_mode().lower() == "light"
            self.btn_auditoria.configure(fg_color="#FEE2E2" if is_light else "#2A1520", 
                                        text_color="#DC2626" if is_light else "#FF9B9B")

    def _btn_nav(self, texto, cmd):
        return ctk.CTkButton(self.frame_lateral, text=texto, command=cmd, anchor="w",
            fg_color="transparent", text_color=self.current_colors["text_secondary"],
            hover_color=self.current_colors["btn_neutral"], corner_radius=10, height=48, 
            font=ctk.CTkFont(family="Segoe UI", size=14, weight="bold"))

    def crear_panel_lateral(self):
        self.frame_lateral = ctk.CTkFrame(self, width=280, corner_radius=0)
        self.frame_lateral.grid(row=0, column=0, sticky="nsew")
        self.frame_lateral.grid_propagate(False)
        self.frame_lateral.grid_rowconfigure(5, weight=1)

        self.logo_label = ctk.CTkLabel(self.frame_lateral, text="USB Bank", font=ctk.CTkFont(family="Segoe UI", size=26, weight="bold"))
        self.logo_label.grid(row=0, column=0, padx=30, pady=(45, 5), sticky="w")

        self.sub_label = ctk.CTkLabel(self.frame_lateral, text="Gestión de Reportes", font=ctk.CTkFont(family="Segoe UI", size=12))
        self.sub_label.grid(row=1, column=0, padx=30, pady=(0, 30), sticky="w")

        self.divider = ctk.CTkFrame(self.frame_lateral, height=1)
        self.divider.grid(row=2, column=0, sticky="ew", padx=30, pady=(0, 25))

        self.btn_clientes = self._btn_nav("📊  Reporte Estadístico", lambda: self.cambiar_seccion("estadistico"))
        self.btn_clientes.grid(row=3, column=0, padx=15, pady=5, sticky="ew")

        self.btn_dinero = self._btn_nav("💰  Reporte Contable", lambda: self.cambiar_seccion("contable"))
        self.btn_dinero.grid(row=4, column=0, padx=15, pady=5, sticky="ew")

        self.btn_auditoria = self._btn_nav("🔍  Auditoría / Limpieza", lambda: self.cambiar_seccion("auditoria"))
        self.btn_auditoria.grid(row=5, column=0, padx=15, pady=5, sticky="nwe")

        self.tema_label = ctk.CTkLabel(self.frame_lateral, text="Preferencia visual", font=ctk.CTkFont(family="Segoe UI", size=11, weight="bold"))
        self.tema_label.grid(row=6, column=0, padx=30, pady=(25, 8), sticky="w")
        
        self.appearance_mode_menu = ctk.CTkOptionMenu(self.frame_lateral, values=["Dark", "Light"], 
                                                      command=self.change_appearance_mode_event, corner_radius=10)
        self.appearance_mode_menu.grid(row=7, column=0, padx=15, pady=(0, 40), sticky="ew")

    def crear_panel_central(self):
        self.frame_central = ctk.CTkFrame(self, fg_color="transparent")
        self.frame_central.grid(row=0, column=1, padx=45, pady=45, sticky="nsew")
        self.frame_central.grid_columnconfigure(0, weight=1)

        self.titulo_seccion = ctk.CTkLabel(self.frame_central, text="Reportes Estadísticos", font=ctk.CTkFont(family="Segoe UI", size=32, weight="bold"))
        self.titulo_seccion.grid(row=0, column=0, sticky="w", pady=(0, 8))

        self.desc_label = ctk.CTkLabel(self.frame_central, text="Seleccione los parámetros para generar el reporte.", font=ctk.CTkFont(family="Segoe UI", size=14))
        self.desc_label.grid(row=1, column=0, sticky="w", pady=(0, 35))

        self.form_frame = ctk.CTkFrame(self.frame_central, corner_radius=15, border_width=1)
        self.form_frame.grid(row=2, column=0, sticky="nsew")
        self.form_frame.grid_columnconfigure((0, 1), weight=1)

        self.lbl_inicio = ctk.CTkLabel(self.form_frame, text="Fecha Inicio", font=ctk.CTkFont(family="Segoe UI", weight="bold", size=13))
        self.lbl_inicio.grid(row=0, column=0, padx=(30, 15), pady=(28, 10), sticky="w")
        self.entry_inicio = ctk.CTkEntry(self.form_frame, placeholder_text="YYYY-MM-DD", height=45, corner_radius=8)
        self.entry_inicio.grid(row=1, column=0, padx=(30, 15), pady=(0, 22), sticky="ew")

        self.lbl_fin = ctk.CTkLabel(self.form_frame, text="Fecha Fin", font=ctk.CTkFont(family="Segoe UI", weight="bold", size=13))
        self.lbl_fin.grid(row=0, column=1, padx=(15, 30), pady=(28, 10), sticky="w")
        self.entry_fin = ctk.CTkEntry(self.form_frame, placeholder_text="YYYY-MM-DD", height=45, corner_radius=8)
        self.entry_fin.grid(row=1, column=1, padx=(15, 30), pady=(0, 22), sticky="ew")

        self.lbl_filtro = ctk.CTkLabel(self.form_frame, text="Filtro de Entidad", font=ctk.CTkFont(family="Segoe UI", weight="bold", size=13))
        self.lbl_filtro.grid(row=2, column=0, columnspan=2, padx=30, pady=(15, 10), sticky="w")
        self.combo_filtro = ctk.CTkComboBox(self.form_frame, values=["Todos", "Natural", "Jurídico"], height=45, corner_radius=8)
        self.combo_filtro.set("Todos")
        self.combo_filtro.grid(row=3, column=0, columnspan=2, padx=30, pady=(0, 30), sticky="ew")

        btn_box = ctk.CTkFrame(self.frame_central, fg_color="transparent")
        btn_box.grid(row=3, column=0, pady=(35, 0), sticky="e")
        
        self.btn_txt = ctk.CTkButton(btn_box, text="Descargar .TXT", width=160, height=48, corner_radius=10, font=ctk.CTkFont(weight="bold"))
        self.btn_txt.pack(side="right", padx=(15, 0))
        self.btn_pdf = ctk.CTkButton(btn_box, text="Exportar a PDF", width=160, height=48, corner_radius=10, font=ctk.CTkFont(weight="bold"))
        self.btn_pdf.pack(side="right")

    def cambiar_seccion(self, seccion):
        self.seccion_activa = seccion
        titulos = {"estadistico": "Reportes Estadísticos", "contable": "Reporte Contable", "auditoria": "Auditoría y Limpieza"}
        self.titulo_seccion.configure(text=titulos.get(seccion))
        self.actualizar_estado_botones()

if __name__ == "__main__":
    app = InterfazBanco()
    app.mainloop()