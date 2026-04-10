import customtkinter as ctk
from tkinter import messagebox
import platform
from PIL import Image, ImageDraw

try:
    from main import obtener_datos_y_generar
except ImportError:
    print(
        "Error: No se encontró main.py. La generación real de reportes no funcionará."
    )

# paletas base para modo oscuro y claro
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
    "btn_neutral_hover": "#484C60",
}

# modo claro ajustado:
# - menos blanco puro
# - tonos crema / gris suave
# - hover más elegante y sin negro
COLORS_LIGHT = {
    "bg": "#E8E2D8",
    "sidebar": "#F4EFE6",
    "card": "#FBF7F1",
    "card_border": "#D8CEC0",
    "text_primary": "#2B2B2B",
    "text_secondary": "#6B7280",
    "accent": "#2563EB",
    "accent_hover": "#1D4ED8",
    "btn_neutral": "#DDD6CB",
    "btn_neutral_hover": "#CFC6B8",
}


class InterfazBanco(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.title("USB Bank — Gestión de Reportes")
        self.geometry("1100x700")

        self.seccion_activa = "estadistico"
        self.current_colors = COLORS_DARK.copy()
        self.es_linux = platform.system().lower() == "linux"
        self.nav_font = (
            ctk.CTkFont(size=14, weight="bold")
            if self.es_linux
            else ctk.CTkFont(family="Segoe UI", size=14, weight="bold")
        )
        self.nav_icons = self._crear_iconos_nav(size=18)
        ctk.set_appearance_mode("dark")

        self.grid_columnconfigure(0, weight=0)
        self.grid_columnconfigure(1, weight=1)
        self.grid_rowconfigure(0, weight=1)

        self.crear_panel_lateral()
        self.crear_panel_central()
        self.update_ui_colors()

    def _icono_estadistico(self, size):
        img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        color = (59, 130, 246, 255)
        base = size - 3
        draw.rectangle((3, base - 6, 6, base), fill=color)
        draw.rectangle((8, base - 10, 11, base), fill=color)
        draw.rectangle((13, base - 14, 16, base), fill=color)
        return img

    def _icono_contable(self, size):
        img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        draw.ellipse((2, 2, size - 2, size - 2), fill=(245, 158, 11, 255))
        draw.ellipse((4, 4, size - 4, size - 4), outline=(146, 64, 14, 255), width=2)
        draw.line((size // 2, 5, size // 2, size - 5), fill=(146, 64, 14, 255), width=2)
        draw.arc((size // 2 - 4, 5, size - 6, size // 2), start=90, end=270, fill=(146, 64, 14, 255), width=2)
        draw.arc((6, size // 2, size // 2 + 4, size - 5), start=270, end=90, fill=(146, 64, 14, 255), width=2)
        return img

    def _icono_auditoria(self, size):
        img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        draw.ellipse((2, 2, size - 8, size - 8), outline=(14, 116, 144, 255), width=3)
        draw.line((size - 8, size - 8, size - 2, size - 2), fill=(14, 116, 144, 255), width=3)
        return img

    def _crear_iconos_nav(self, size=18):
        return {
            "estadistico": ctk.CTkImage(
                light_image=self._icono_estadistico(size),
                dark_image=self._icono_estadistico(size),
                size=(size, size),
            ),
            "contable": ctk.CTkImage(
                light_image=self._icono_contable(size),
                dark_image=self._icono_contable(size),
                size=(size, size),
            ),
            "auditoria": ctk.CTkImage(
                light_image=self._icono_auditoria(size),
                dark_image=self._icono_auditoria(size),
                size=(size, size),
            ),
        }

    def comando_generar_reporte(self, formato):
        inicio = self.entry_inicio.get().strip()
        fin = self.entry_fin.get().strip()
        estado = self.combo_estado.get().strip()

        filtros = {
            "inicio": inicio if inicio else None,
            "fin": fin if fin else None,
            "tipo": self.combo_filtro.get(),
            "canal": "Todos",
            "estado_movimiento": estado if estado else "Todos",
            "agrupar_por": self.combo_filtro.get().lower()
            if self.seccion_activa == "contable"
            else "cliente",
            "formato_deseado": formato,
        }

        if self.seccion_activa == "contable" and filtros["agrupar_por"] not in [
            "cuenta",
            "cliente",
            "canal",
            "tarjeta",
        ]:
            filtros["agrupar_por"] = "cliente"

        try:
            print(
                f"\n--- Generando {self.seccion_activa.upper()} en formato {formato.upper()} ---"
            )
            obtener_datos_y_generar(self.seccion_activa, filtros)
            messagebox.showinfo(
                "Éxito",
                f"Reporte {self.seccion_activa} ({formato.upper()}) generado correctamente.",
            )
        except Exception as e:
            messagebox.showerror("Error", f"No se pudo generar el reporte: {e}")

    def cambiar_seccion(self, seccion):
        self.seccion_activa = seccion

        if seccion == "estadistico":
            self.titulo_seccion.configure(text="Reportes Estadísticos")
            self._mostrar_filtro()
            self._ocultar_estado()
            self.combo_filtro.configure(
                state="normal", values=["Todos", "Natural", "Juridico"]
            )
            self.combo_filtro.set("Todos")
            self.entry_inicio.configure(state="normal")
            self.entry_fin.configure(state="normal")

        elif seccion == "contable":
            self.titulo_seccion.configure(text="Reporte Contable")
            self._mostrar_filtro()
            self._mostrar_estado()
            self.combo_filtro.configure(
                state="normal", values=["Cliente", "Cuenta", "Canal", "Tarjeta"]
            )
            self.combo_filtro.set("Cliente")
            self.combo_estado.configure(
                state="normal",
                values=["Todos", "Completado", "Pendiente", "Fallido", "Reversado"],
            )
            self.combo_estado.set("Todos")
            self.entry_inicio.configure(state="normal")
            self.entry_fin.configure(state="normal")

        elif seccion == "auditoria":
            self.titulo_seccion.configure(text="Auditoría y Limpieza")
            self._ocultar_filtro()
            self._ocultar_estado()
            self.entry_inicio.configure(state="normal")
            self.entry_fin.configure(state="normal")

        self.actualizar_estado_botones()

    def _mostrar_filtro(self):
        self.lbl_filtro.grid(
            row=2, column=0, columnspan=2, padx=30, pady=(15, 10), sticky="w"
        )
        self.combo_filtro.grid(
            row=3, column=0, columnspan=2, padx=30, pady=(0, 30), sticky="ew"
        )

    def _ocultar_filtro(self):
        self.lbl_filtro.grid_remove()
        self.combo_filtro.grid_remove()

    def _mostrar_estado(self):
        self.lbl_estado.grid(
            row=4, column=0, columnspan=2, padx=30, pady=(0, 10), sticky="w"
        )
        self.combo_estado.grid(
            row=5, column=0, columnspan=2, padx=30, pady=(0, 30), sticky="ew"
        )

    def _ocultar_estado(self):
        self.lbl_estado.grid_remove()
        self.combo_estado.grid_remove()

    def lerp_color(self, c1, c2, t):
        def h2r(h):
            return [int(h.lstrip("#")[i : i + 2], 16) for i in (0, 2, 4)]

        r1, g1, b1 = h2r(c1)
        r2, g2, b2 = h2r(c2)
        r, g, b = [
            int(v1 + (v2 - v1) * t) for v1, v2 in zip([r1, g1, b1], [r2, g2, b2])
        ]
        return f"#{r:02x}{g:02x}{b:02x}"

    def animate_transition(self, target_palette, steps=10):
        start_palette = self.current_colors.copy()
        for i in range(1, steps + 1):
            t = i / steps
            temp_colors = {
                k: self.lerp_color(start_palette[k], target_palette[k], t)
                for k in target_palette
                if k in start_palette
            }
            self.current_colors.update(temp_colors)
            self.update_ui_colors(is_partial=True)
            self.update_idletasks()
            self.after(5)
        self.current_colors = target_palette.copy()
        self.update_ui_colors()

    def update_ui_colors(self, is_partial=False):
        c = self.current_colors
        appearance = ctk.get_appearance_mode().lower()

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

            for lbl in [
                self.lbl_inicio,
                self.lbl_fin,
                self.lbl_filtro,
                self.lbl_estado,
            ]:
                lbl.configure(text_color=c["text_secondary"])

            input_bg = c["card"] if appearance == "light" else c["bg"]

            self.entry_inicio.configure(
                fg_color=input_bg,
                border_color=c["card_border"],
                text_color=c["text_primary"],
            )
            self.entry_fin.configure(
                fg_color=input_bg,
                border_color=c["card_border"],
                text_color=c["text_primary"],
            )
            self.combo_filtro.configure(
                fg_color=input_bg,
                border_color=c["card_border"],
                text_color=c["text_primary"],
                button_color=c["btn_neutral"],
                button_hover_color=c["btn_neutral_hover"],
                dropdown_fg_color=c["card"],
                dropdown_hover_color=c["btn_neutral_hover"],
                dropdown_text_color=c["text_primary"],
            )
            self.combo_estado.configure(
                fg_color=input_bg,
                border_color=c["card_border"],
                text_color=c["text_primary"],
                button_color=c["btn_neutral"],
                button_hover_color=c["btn_neutral_hover"],
                dropdown_fg_color=c["card"],
                dropdown_hover_color=c["btn_neutral_hover"],
                dropdown_text_color=c["text_primary"],
            )

            self.btn_pdf.configure(
                fg_color=c["accent"],
                hover_color=c["accent_hover"],
                text_color="#FFFFFF",
            )
            self.btn_txt.configure(
                fg_color=c["btn_neutral"],
                hover_color=c["btn_neutral_hover"],
                text_color=c["text_primary"],
            )
            self.appearance_mode_menu.configure(
                fg_color=c["btn_neutral"],
                button_color=c["btn_neutral"],
                button_hover_color=c["btn_neutral_hover"],
                text_color=c["text_primary"],
                dropdown_fg_color=c["card"],
                dropdown_hover_color=c["btn_neutral_hover"],
                dropdown_text_color=c["text_primary"],
            )
            self.actualizar_estado_botones()

    def change_appearance_mode_event(self, new_mode):
        target = COLORS_LIGHT if new_mode.lower() == "light" else COLORS_DARK
        ctk.set_appearance_mode(new_mode)
        self.animate_transition(target)

    def actualizar_estado_botones(self):
        c = self.current_colors
        appearance = ctk.get_appearance_mode().lower()

        for btn in [self.btn_clientes, self.btn_dinero, self.btn_auditoria]:
            btn.configure(
                fg_color="transparent",
                text_color=c["text_secondary"],
                hover_color=c["btn_neutral"],
            )

        mapping = {"estadistico": self.btn_clientes, "contable": self.btn_dinero}
        if self.seccion_activa in mapping:
            mapping[self.seccion_activa].configure(
                fg_color=c["btn_neutral"],
                text_color=c["text_primary"],
                hover_color=c["btn_neutral_hover"],
            )
        elif self.seccion_activa == "auditoria":
            self.btn_auditoria.configure(
                fg_color="#F5D7D7" if appearance == "light" else "#2A1520",
                text_color="#B42318" if appearance == "light" else "#FF9B9B",
                hover_color="#E9C1C1" if appearance == "light" else "#6A1515",
            )

    def _btn_nav(self, seccion, texto, cmd):
        return ctk.CTkButton(
            self.frame_lateral,
            text=texto,
            command=cmd,
            image=self.nav_icons.get(seccion),
            compound="left",
            anchor="center",
            fg_color="transparent",
            text_color=self.current_colors["text_secondary"],
            hover_color=self.current_colors["btn_neutral"],
            corner_radius=10,
            width=180,
            height=50,
            font=self.nav_font,
        )

    def crear_panel_lateral(self):
        self.frame_lateral = ctk.CTkFrame(self, width=280, corner_radius=0)
        self.frame_lateral.grid(row=0, column=0, sticky="nsew")
        self.frame_lateral.grid_propagate(False)
        self.frame_lateral.grid_rowconfigure(5, weight=1)
        self.frame_lateral.grid_columnconfigure(0, weight=1)

        self.logo_label = ctk.CTkLabel(
            self.frame_lateral,
            text="USB Bank",
            font=ctk.CTkFont(family="Segoe UI", size=38, weight="bold"),
            justify="center",
        )
        self.logo_label.grid(row=0, column=0, padx=20, pady=(45, 5), sticky="ew")

        self.sub_label = ctk.CTkLabel(
            self.frame_lateral,
            text="Gestión de Reportes",
            font=ctk.CTkFont(family="Segoe UI", size=14),
            justify="center",
        )
        self.sub_label.grid(row=1, column=0, padx=20, pady=(0, 30), sticky="ew")

        self.divider = ctk.CTkFrame(self.frame_lateral, height=1)
        self.divider.grid(row=2, column=0, sticky="ew", padx=30, pady=(0, 25))

        self.btn_clientes = self._btn_nav(
            "estadistico",
            "Reporte Estadístico",
            lambda: self.cambiar_seccion("estadistico"),
        )
        self.btn_clientes.grid(row=3, column=0, padx=25, pady=6)

        self.btn_dinero = self._btn_nav(
            "contable",
            "Reporte Contable",
            lambda: self.cambiar_seccion("contable"),
        )
        self.btn_dinero.grid(row=4, column=0, padx=25, pady=6)

        self.btn_auditoria = self._btn_nav(
            "auditoria",
            "Auditoría / Limpieza",
            lambda: self.cambiar_seccion("auditoria"),
        )
        self.btn_auditoria.grid(row=5, column=0, padx=25, pady=6, sticky="n")

        self.tema_label = ctk.CTkLabel(
            self.frame_lateral,
            text="Preferencia visual",
            font=ctk.CTkFont(family="Segoe UI", size=11, weight="bold"),
            justify="center",
        )
        self.tema_label.grid(row=6, column=0, padx=20, pady=(25, 8), sticky="ew")

        self.appearance_mode_menu = ctk.CTkOptionMenu(
            self.frame_lateral,
            values=["Dark", "Light"],
            command=self.change_appearance_mode_event,
            corner_radius=10,
        )
        self.appearance_mode_menu.grid(
            row=7, column=0, padx=25, pady=(0, 40), sticky="ew"
        )

    def crear_panel_central(self):
        self.frame_central = ctk.CTkFrame(self, fg_color="transparent")
        self.frame_central.grid(row=0, column=1, padx=45, pady=45, sticky="nsew")
        self.frame_central.grid_columnconfigure(0, weight=1)

        self.titulo_seccion = ctk.CTkLabel(
            self.frame_central,
            text="Reportes Estadísticos",
            font=ctk.CTkFont(family="Segoe UI", size=32, weight="bold"),
        )
        self.titulo_seccion.grid(row=0, column=0, sticky="w", pady=(0, 8))

        self.desc_label = ctk.CTkLabel(
            self.frame_central,
            text="Seleccione los parámetros para generar el reporte.",
            font=ctk.CTkFont(family="Segoe UI", size=14),
        )
        self.desc_label.grid(row=1, column=0, sticky="w", pady=(0, 35))

        self.form_frame = ctk.CTkFrame(
            self.frame_central, corner_radius=15, border_width=1
        )
        self.form_frame.grid(row=2, column=0, sticky="nsew")
        self.form_frame.grid_columnconfigure((0, 1), weight=1)

        self.lbl_inicio = ctk.CTkLabel(
            self.form_frame,
            text="Fecha Inicio",
            font=ctk.CTkFont(family="Segoe UI", weight="bold", size=13),
        )
        self.lbl_inicio.grid(row=0, column=0, padx=(30, 15), pady=(28, 10), sticky="w")

        self.entry_inicio = ctk.CTkEntry(
            self.form_frame, placeholder_text="YYYY-MM-DD", height=45, corner_radius=8
        )
        self.entry_inicio.grid(
            row=1, column=0, padx=(30, 15), pady=(0, 22), sticky="ew"
        )

        self.lbl_fin = ctk.CTkLabel(
            self.form_frame,
            text="Fecha Fin",
            font=ctk.CTkFont(family="Segoe UI", weight="bold", size=13),
        )
        self.lbl_fin.grid(row=0, column=1, padx=(15, 30), pady=(28, 10), sticky="w")

        self.entry_fin = ctk.CTkEntry(
            self.form_frame, placeholder_text="YYYY-MM-DD", height=45, corner_radius=8
        )
        self.entry_fin.grid(row=1, column=1, padx=(15, 30), pady=(0, 22), sticky="ew")

        self.lbl_filtro = ctk.CTkLabel(
            self.form_frame,
            text="Filtro de Entidad",
            font=ctk.CTkFont(family="Segoe UI", weight="bold", size=13),
        )
        self.lbl_filtro.grid(
            row=2, column=0, columnspan=2, padx=30, pady=(15, 10), sticky="w"
        )

        self.combo_filtro = ctk.CTkComboBox(
            self.form_frame,
            values=["Todos", "Natural", "Jurídico"],
            height=45,
            corner_radius=8,
        )
        self.combo_filtro.set("Todos")
        self.combo_filtro.grid(
            row=3, column=0, columnspan=2, padx=30, pady=(0, 30), sticky="ew"
        )

        self.lbl_estado = ctk.CTkLabel(
            self.form_frame,
            text="Estado del Movimiento",
            font=ctk.CTkFont(family="Segoe UI", weight="bold", size=13),
        )
        self.lbl_estado.grid(
            row=4, column=0, columnspan=2, padx=30, pady=(0, 10), sticky="w"
        )

        self.combo_estado = ctk.CTkComboBox(
            self.form_frame,
            values=["Todos", "Completado", "Pendiente", "Fallido", "Reversado"],
            height=45,
            corner_radius=8,
        )
        self.combo_estado.set("Todos")
        self.combo_estado.grid(
            row=5, column=0, columnspan=2, padx=30, pady=(0, 30), sticky="ew"
        )
        self._ocultar_estado()

        btn_box = ctk.CTkFrame(self.frame_central, fg_color="transparent")
        btn_box.grid(row=3, column=0, pady=(35, 0), sticky="e")

        self.btn_txt = ctk.CTkButton(
            btn_box,
            text="Exportar a TXT",
            width=160,
            height=48,
            corner_radius=10,
            font=ctk.CTkFont(weight="bold"),
            command=lambda: self.comando_generar_reporte("txt"),
        )
        self.btn_txt.pack(side="right", padx=(15, 0))

        self.btn_pdf = ctk.CTkButton(
            btn_box,
            text="Exportar a PDF",
            width=160,
            height=48,
            corner_radius=10,
            font=ctk.CTkFont(weight="bold"),
            command=lambda: self.comando_generar_reporte("pdf"),
        )
        self.btn_pdf.pack(side="right")


if __name__ == "__main__":
    app = InterfazBanco()
    app.mainloop()