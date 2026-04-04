USB Bank - Sistema de Gestión Bancaria (Fase III)

Este repositorio contiene la implementación de la Fase III del proyecto para la asignatura CI-3391: Laboratorio de Sistemas de Bases de Datos I. El sistema consiste en un Core Transaccional Bancario que integra una interfaz gráfica de usuario (GUI) con una base de datos PostgreSQL altamente normalizada.

1. Descripción General

USB Bank es una aplicación diseñada para la gestión financiera digital. Permite el monitoreo de operaciones, la consulta de saldos y la generación de reportes analíticos para la toma de decisiones gerenciales. La arquitectura se basa en el cumplimiento de las reglas de integridad referencial y las propiedades ACID para garantizar la fiabilidad de las transacciones.

2. Especificaciones Técnicas

- Motor de Base de Datos: PostgreSQL 16+.
- Lenguaje de Desarrollo: Python 3.10+.
- Adaptador de Base de Datos: psycopg2-binary.
- Framework de Interfaz: CustomTkinter (basado en Tcl/Tk).
- Procesamiento de Reportes: pandas y fpdf2.
- Normatividad: Tercera Forma Normal (3FN) con lógica de herencia de tablas (STI).

3. Características Principales

- Módulo de Consultas Estadísticas: Análisis de productos y saldos consolidados por cliente con filtrado paramétrico por rango de fechas y canal de origen.
- Módulo de Reportes Contables: Balance de flujo de caja (Ingresos vs Egresos) con capacidad de agrupación por Cuenta, Cliente, Canal o Instrumento (Tarjeta).
- Generación de Salidas: Exportación automatizada en formato de texto plano (.txt) y reportes corporativos en formato PDF.
- Gestión de Seguridad: Manejo de excepciones para errores de red, fallos de autenticación en el servidor y validaciones estructurales de base de datos.

4. Estructura del Proyecto
La estructura del repositorio está diseñada de forma modular para separar la lógica de datos de la lógica de presentación:

- docs/: Directorio que centraliza la documentación oficial. Incluye el Documento Funcional (FUNC), el Documento Técnico (TECN) y las diapositivas de la defensa (PRES).
- sql/: Contiene los scripts SQL necesarios para el despliegue. Incluye el DDL de creación de tablas, el DML de carga de datos iniciales y los archivos con los queries analíticos optimizados.
- src/: Carpeta raíz del código fuente de la aplicación.
  - main.py: Archivo principal encargado de orquestar el inicio del sistema y la integración de módulos.
  - database.py: Módulo de persistencia que gestiona la conectividad y ejecución de sentencias sobre PostgreSQL.
  - nterfaz_banco.py: Definición de la capa visual, formularios de filtrado y visualización de resultados.
  - generador_reportes.py: Lógica de procesamiento de datos para la generación de archivos físicos.
- reportes_generados/: Carpeta de destino automatizada para las salidas generadas en formato .txt y .pdf.
- requirements.txt: Archivo de configuración de dependencias para el entorno de ejecución de Python.

5. Instalación y Despliegue

Requisitos Previos

- Servidor PostgreSQL activo con una base de datos denominada usb_bank.
- Intérprete de Python instalado en el sistema.

Pasos de Ejecución

- Configuración de Datos:
Importar el script maestro ubicado en sql/MASTER_SCRIPT.sql para crear la estructura de tablas y cargar los datos de prueba.
- Entorno Virtual (Recomendado):
  python3 -m venv venv
  source venv/bin/activate # En Windows: venv\Scripts\activate
- Instalación de Dependencias:
  pip install -r requirements.txt
- Inicio de la Aplicación:
  python src/main.py

6. Equipo de Desarrollo (Sección 01)

- Pacheco, Ángel - 20-10479 - Líder de Proyecto, Integración e Infraestructura
- Ramírez, Rosa - 20-10527 - Documentación Técnica y Teoría de Normalización
- García, Ricardo - 20-10274 - Backend y Módulo de Exportación
- Orta, Brian - 21-10447 - Ingeniería de Datos y SQL Analítico
- Isea, Luis M - 19-10175 - Análisis Estructural y Estrategia de Defensa
- Valero, Angel - 18-10436 - Frontend y Diseño de Experiencia de Usuario

7. Información Académica

- Institución: Universidad Simón Bolívar (Sartenejas).
- Materia: CI-3391 Laboratorio de Sistemas de Bases de Datos I.
- Profesor: Kendy Briceño.
- Período: Trimestre Enero - Marzo 2026.
