## USB Bank - Sistema de Gestión Bancaria (Proyecto Fase III)
![Made with Love](https://img.shields.io/badge/Made%20with-Love-pink?style=for-the-badge&logo=data:image/svg%2bxml;base64,PHN2ZyByb2xlPSJpbWciIHZpZXdCb3g9IjAgMCAyNCAyNCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48dGl0bGU+R2l0SHViIFNwb25zb3JzIGljb248L3RpdGxlPjxwYXRoIGQ9Ik0xNy42MjUgMS40OTljLTIuMzIgMC00LjM1NCAxLjIwMy01LjYyNSAzLjAzLTEuMjcxLTEuODI3LTMuMzA1LTMuMDMtNS42MjUtMy4wM0MzLjEyOSAxLjQ5OSAwIDQuMjUzIDAgOC4yNDljMCA0LjI3NSAzLjA2OCA3Ljg0NyA1LjgyOCAxMC4yMjdhMzMuMTQgMzMuMTQgMCAwIDAgNS42MTYgMy44NzZsLjAyOC4wMTcuMDA4LjAwMy0uMDAxLjAwM2MuMTYzLjA4NS4zNDIuMTI2LjUyMS4xMjUuMTc5LjAwMS4zNTgtLjA0MS41MjEtLjEyNWwtLjAwMS0uMDAzLjAwOC0uMDAzLjAyOC0uMDE3YTMzLjE0IDMzLjE0IDAgMCAwIDUuNjE2LTMuODc2QzIwLjkzMiAxNi4wOTYgMjQgMTIuNTI0IDI0IDguMjQ5YzAtMy45OTYtMy4xMjktNi43NS02LjM3NS02Ljc1em0tLjkxOSAxNS4yNzVhMzAuNzY2IDMwLjc2NiAwIDAgMS00LjcwMyAzLjMxNmwtLjAwNC0uMDAyLS4wMDQuMDAyYTMwLjk1NSAzMC45NTUgMCAwIDEtNC43MDMtMy4zMTZjLTIuNjc3LTIuMzA3LTUuMDQ3LTUuMjk4LTUuMDQ3LTguNTIzIDAtMi43NTQgMi4xMjEtNC41IDQuMTI1LTQuNSAyLjA2IDAgMy45MTQgMS40NzkgNC41NDQgMy42ODQuMTQzLjQ5NS41OTYuNzk3IDEuMDg2Ljc5Ni40OS4wMDEuOTQzLS4zMDIgMS4wODUtLjc5Ni42My0yLjIwNSAyLjQ4NC0zLjY4NCA0LjU0NC0zLjY4NCAyLjAwNCAwIDQuMTI1IDEuNzQ2IDQuMTI1IDQuNSAwIDMuMjI1LTIuMzcgNi4yMTYtNS4wNDggOC41MjN6Ii8+PC9zdmc+)

Universidad Simón Bolívar (Sartenejas)  
CI-3391 Laboratorio de Sistemas de Bases de Datos I  
Profesor: Kendy Briceño  
Período: Trimestre Enero - Marzo 2026.

Este repositorio contiene la implementación de la Fase III del proyecto para la asignatura CI-3391: Laboratorio de Sistemas de Bases de Datos I. El sistema consiste en un Core Transaccional Bancario que integra una interfaz gráfica de usuario (GUI) con una base de datos PostgreSQL altamente normalizada.

### 1. Descripción General

USB Bank es una aplicación diseñada para la gestión financiera digital. Permite el monitoreo de operaciones, la consulta de saldos y la generación de reportes analíticos para la toma de decisiones gerenciales. La arquitectura se basa en el cumplimiento de las reglas de integridad referencial y las propiedades ACID para garantizar la fiabilidad de las transacciones.

### 2. Especificaciones Técnicas

- Motor de Base de Datos: PostgreSQL 16+.
- Lenguaje de Desarrollo: Python 3.10+.
- Adaptador de Base de Datos: psycopg2-binary.
- Framework de Interfaz: CustomTkinter (basado en Tcl/Tk).
- Procesamiento de Reportes: pandas y fpdf2.
- Normatividad: Tercera Forma Normal (3FN) con lógica de herencia de tablas (STI).

### 3. Características Principales

- Módulo de Consultas Estadísticas: Análisis de productos y saldos consolidados por cliente con filtrado paramétrico por rango de fechas y canal de origen.
- Módulo de Reportes Contables: Balance de flujo de caja (Ingresos vs Egresos) con capacidad de agrupación por Cuenta, Cliente, Canal o Instrumento (Tarjeta).
- Generación de Salidas: Exportación automatizada en formato de texto plano (.txt) y reportes corporativos en formato PDF.
- Gestión de Seguridad: Manejo de excepciones para errores de red, fallos de autenticación en el servidor y validaciones estructurales de base de datos.

### 4. Estructura del Proyecto
La estructura del repositorio está diseñada de forma modular para separar la lógica de datos de la lógica de presentación:

- docs/: Directorio que centraliza la documentación oficial. Incluye el Documento Funcional (FUNC), el Documento Técnico (TECN) y las diapositivas de la defensa (PRES).
- sql/: Contiene los scripts SQL necesarios para el despliegue. Incluye el DDL de creación de tablas, el DML de carga de datos iniciales y los archivos con los queries analíticos optimizados.
- src/: Carpeta raíz del código fuente de la aplicación.
  - main.py: Archivo principal encargado de orquestar el inicio del sistema y la integración de módulos.
  - config.py: Módulo de configuración para la conexión a PostgreSQL mediante database.ini.
  - interfaz_banco.py: Definición de la capa visual, formularios de filtrado y visualización de resultados.
  - generador_reportes.py: Lógica de procesamiento de datos para la generación de archivos físicos.
- reportes_generados/: Carpeta de destino automatizada para las salidas generadas en formato .txt y .pdf.
- requirements.txt: Archivo de configuración de dependencias para el entorno de ejecución de Python.

### 5. Instalación y Despliegue

#### Requisitos Previos

- Servidor PostgreSQL activo con una base de datos denominada usb_bank.
- Intérprete de Python instalado en el sistema.

#### Pasos de Instalación

- Configuración de Datos:
  - Ejecutar los scripts SQL del directorio sql/ en orden para crear el esquema y cargar datos de prueba:
    - sql/01_esquema_master.sql
    - sql/02_inserts_datos.sql
    - sql/03_funciones_reportes_estadistico.sql
    - sql/04_funciones_reportes_contables.sql
    - sql/05_procedimientos_consola.sql
- Entorno Virtual (Recomendado):
  - Linux/macOS:

```bash
python3 -m venv venv
source venv/bin/activate
```

  - Windows (PowerShell):

```powershell
python -m venv venv
venv\Scripts\activate
```

- Instalación de Dependencias:

```bash
pip install -r requirements.txt
```

#### Configuración de Conexión (database.ini)

Además de lo anterior, debes configurar el archivo src/database.ini para indicar la base de datos a utilizar.

Ejemplo mínimo:

```ini
[postgresql]
host=localhost
port=5432
database=usb_bank
user=tu_usuario
password=tu_clave
```

Si deseas usar otra base de datos, actualiza estos valores en src/database.ini antes de ejecutar la aplicación.

### 6. Cómo Usar

- Paso 1 (inicial): ejecutar una vez src/main.py para validar y establecer la conexión con la BBDD.

```bash
# Linux/macOS
python3 src/main.py

# Windows
python src\main.py
```

- Paso 2 (uso diario): ejecutar directamente la interfaz gráfica.

```bash
# Linux/macOS
python3 src/interfaz_banco.py

# Windows
python src\interfaz_banco.py
```

Desde la GUI podrás seleccionar filtros, tipo de reporte y formato de salida (txt/pdf).

### 7. Equipo de Desarrollo (Equipo A)

- **Pacheco, Ángel** - Líder de Proyecto: Integración de módulos e infraestructura, supervisión general del proyecto y verificación integral de la consistencia técnica y documental.
- **Ramírez, Rosa** - Documentación y Teoría: Normalización formal, Reunión sin Pérdida, manuales y co-desarrollo de interfaz gráfica, reportes, funciones y procedimientos.
- **García, Ricardo** - Backend y Exportación: Lógica Python, fpdf2, pandas y manejo de excepciones.
- **Orta, Brian** - Ingeniería de Datos: SQL analítico, optimización de queries y validación ACID.
- **Isea, Luis M.** - Análisis Estructural: Estrategia de defensa, validación de restricciones y co-desarrollo de interfaz gráfica, reportes, funciones y procedimientos.
- **Valero, Ángel** - Frontend y UX: Interfaz gráfica CustomTkinter, flujo de reportes y validaciones UI.
