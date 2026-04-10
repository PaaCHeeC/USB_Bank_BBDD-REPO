# MAKEFILE - USB BANK (Automatización de Entorno y Despliegue)
# USO:
# 1. "make install" -> Prepara la computadora desde cero (Instala todo)
# 2. "make run"     -> Ejecuta la aplicación gráfica
# 3. "make gen"	    -> Borra reportes y cache generados (.txt .pdf)
# 4. "make clean"   -> Borra el entorno para dejar la PC limpia al irse

# Variables
VENV_DIR = .venv
PYTHON = $(VENV_DIR)/bin/python3
PIP = $(VENV_DIR)/bin/pip

.PHONY: help install system-deps venv deps run clean

# Comando por defecto
help:
	@echo Comandos soportados
	@echo "make install  - Instala dependencias de Linux y Python"
	@echo "make run      - Ejecuta la aplicación (Abre la GUI)"
	@echo "make clean    - Elimina el entorno virtual y la caché"

# COMANDO MAESTRO (Ejecuta todo en orden)
install: system-deps venv deps
	@echo "INSTALACIÓN COMPLETADA. Ejecuta 'make run' para iniciar."

# 1. Instala dependencias del Sistema Operativo (Requiere sudo)
system-deps:
	@echo "[1/3] Instalando dependencias de Linux (Debian/Ubuntu)..."
	sudo apt-get update
	sudo apt-get install -y python3 python3-pip python3-venv python3-tk libpq-dev git

# 2. Crea el entorno virtual aislado
venv:
	@echo "[2/3] Creando el entorno virtual en $(VENV_DIR)..."
	python3 -m venv $(VENV_DIR)

# 3. Instala las librerías de Python dentro del entorno virtual
deps:
	@echo "[3/3] Descargando librerías de Python..."
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt

# COMANDO PARA EJECUTAR EL BANCO
run:
	@echo "Iniciando USB Bank..."
	$(PYTHON) src/main.py
	$(PYTHON) src/interfaz_banco.py

# COMANDO PARA LIMPIAR REPORTES Y CACHE
gen:
	@echo "Limpiando reportes generados y archivos temporales..."
	rm -rf reportes_generados/
	find . -type d -name "__pycache__" -exec rm -rf {} +
	@echo "Limpieza terminada con éxito."

# COMANDO PARA LIMPIAR LA PC AL TERMINAR LA DEFENSA
clean:
	@echo "Limpiando el entorno y archivos temporales..."
	rm -rf $(VENV_DIR)
	rm -rf reportes_generados/
	find . -type d -name "__pycache__" -exec rm -rf {} +
	@echo "Limpieza terminada con éxito."
