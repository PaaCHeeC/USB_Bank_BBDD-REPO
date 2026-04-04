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

USB_Bank_Fase3/
├── docs/ # Documentación Funcional, Técnica y Presentación.
├── sql/ # DDL de creación, DML de carga y consultas de negocio.
├── src/ # Código fuente de la aplicación principal.
│ ├── main.py # Punto de entrada y orquestador del sistema.
│ ├── database.py # Módulo de conectividad y ejecución SQL.
│ ├── interfaz_banco.py # Definición de la lógica de presentación (GUI).
│ └── generador_reportes.py # Módulo de procesamiento y exportación de archivos.
├── reportes_generados/ # Directorio destinado a las salidas del sistema.
└── requirements.txt # Especificación de dependencias del entorno.

5. Instalación y Despliegue

Requisitos Previos

- Servidor PostgreSQL activo con una base de datos denominada usb_bank.
- Intérprete de Python instalado en el sistema.

Pasos de Ejecución

i. Configuración de Datos:
Importar el script maestro ubicado en sql/MASTER_SCRIPT.sql para crear la estructura de tablas y cargar los datos de prueba.

ii. Entorno Virtual (Recomendado):

python3 -m venv venv
source venv/bin/activate # En Windows: venv\Scripts\activate

iii. Instalación de Dependencias:

pip install -r requirements.txt

iv. Inicio de la Aplicación:

python src/main.py

6. Equipo de Desarrollo (Sección 01)

Pacheco, Ángel - 20-10479 - Líder de Proyecto, Integración e Infraestructura

Ramírez, Rosa - 20-10527 - Documentación Técnica y Teoría de Normalización

García, Ricardo - 20-10274 - Backend y Módulo de Exportación

Orta, Brian - 21-10447 - Ingeniería de Datos y SQL Analítico

Isea, Luis - 19-10175 - Análisis Estructural y Estrategia de Defensa

Valero, Angel - 18-10436 - Frontend y Diseño de Experiencia de Usuario

7. Información Académica

- Institución: Universidad Simón Bolívar (Sartenejas).
- Materia: CI-3391 Laboratorio de Sistemas de Bases de Datos I.
- Profesor: Kendy Briceño.
- Período: Trimestre Enero - Marzo 2026.
