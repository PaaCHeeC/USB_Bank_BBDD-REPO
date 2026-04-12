--- CONFIGURACION DE ESQUEMA NORMALIZADO ---
-- Representa el estado de la BD después de aplicar BCNF, 4FN y 5FN
DROP SCHEMA IF EXISTS "usb_bank" CASCADE;
CREATE SCHEMA "usb_bank";
SET search_path TO "usb_bank";

--- CATALOGOS BASE ---
CREATE TABLE "BANCO" (
    id_banco SERIAL PRIMARY KEY,
    nombre_banco VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE "MARCA" (
    id_marca SERIAL PRIMARY KEY,
    nombre_marca VARCHAR(50) NOT NULL UNIQUE,
    bin VARCHAR(6)
);

CREATE TABLE "TIPO_MOVIMIENTO" (
    id_tipo_mov SERIAL PRIMARY KEY,
    descripcion VARCHAR(100) NOT NULL
);

CREATE TABLE "TIPO_DOCUMENTO" (
    id_tipo_doc VARCHAR(10) PRIMARY KEY,
    descripcion VARCHAR(100) NOT NULL
);

--- ========================================================= ---
--- MODIFICACIÓN BCNF (1.1): EXTRACCIÓN DE IDENTIDAD
--- ========================================================= ---
CREATE TABLE "DOCUMENTO_IDENTIDAD" (
    nro_documento VARCHAR(20) PRIMARY KEY,
    id_tipo_doc VARCHAR(10) NOT NULL,
    CONSTRAINT fk_doc_tipo FOREIGN KEY (id_tipo_doc) REFERENCES "TIPO_DOCUMENTO"(id_tipo_doc)
);

--- CANALES ---
CREATE TABLE "CANAL" (
    id_canal SERIAL PRIMARY KEY,
    tipo_canal VARCHAR(50) NOT NULL,
    descripcion VARCHAR(100) NOT NULL,
    CONSTRAINT chk_tipo_canal CHECK (tipo_canal IN ('Digital', 'Electronico'))
);

CREATE TABLE "CANAL_DIGITAL" (
    id_canal INTEGER PRIMARY KEY,
    plataforma VARCHAR(50) NOT NULL,
    CONSTRAINT fk_cdigital_canal FOREIGN KEY (id_canal) REFERENCES "CANAL"(id_canal) ON DELETE CASCADE
);

CREATE TABLE "CANAL_WEB" (
    id_canal INTEGER PRIMARY KEY,
    url VARCHAR(255) NOT NULL,
    CONSTRAINT fk_cweb_cdigital FOREIGN KEY (id_canal) REFERENCES "CANAL_DIGITAL"(id_canal) ON DELETE CASCADE
);

CREATE TABLE "CANAL_APP_MOVIL" (
    id_canal INTEGER PRIMARY KEY,
    nfc BOOLEAN NOT NULL,
    CONSTRAINT fk_capp_cdigital FOREIGN KEY (id_canal) REFERENCES "CANAL_DIGITAL"(id_canal) ON DELETE CASCADE
);

CREATE TABLE "CANAL_ELECTRONICO" (
    id_canal INTEGER PRIMARY KEY,
    CONSTRAINT fk_celectronico_canal FOREIGN KEY (id_canal) REFERENCES "CANAL"(id_canal) ON DELETE CASCADE
);

CREATE TABLE "CANAL_ATM" (
    id_canal INTEGER PRIMARY KEY,
    id_atm VARCHAR(50) NOT NULL UNIQUE,
    ubicacion TEXT NOT NULL,
    efectivo_disponible NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    CONSTRAINT fk_catm_celectronico FOREIGN KEY (id_canal) REFERENCES "CANAL_ELECTRONICO"(id_canal) ON DELETE CASCADE
);

CREATE TABLE "CANAL_POS" (
    id_canal INTEGER PRIMARY KEY,
    id_pos VARCHAR(50) NOT NULL UNIQUE,
    CONSTRAINT fk_cpos_celectronico FOREIGN KEY (id_canal) REFERENCES "CANAL_ELECTRONICO"(id_canal) ON DELETE CASCADE
);

CREATE TABLE "CANAL_IVR" (
    id_canal INTEGER PRIMARY KEY,
    id_ivr VARCHAR(50) NOT NULL UNIQUE,
    CONSTRAINT fk_civr_celectronico FOREIGN KEY (id_canal) REFERENCES "CANAL_ELECTRONICO"(id_canal) ON DELETE CASCADE
);

--- CLIENTES Y KYC ---
CREATE TABLE "CLIENTE" (
    id_cliente SERIAL PRIMARY KEY,
    tipo_cliente VARCHAR(20) NOT NULL,
    id_canal_onboarding INTEGER NOT NULL,
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usuario VARCHAR(50) NOT NULL UNIQUE,
    clave VARCHAR(255) NOT NULL,
    direccion TEXT NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'activo',
    rif VARCHAR(20),
    CONSTRAINT chk_tipo_cliente CHECK (tipo_cliente IN ('Natural', 'Juridico')),
    CONSTRAINT fk_cliente_canal FOREIGN KEY (id_canal_onboarding) REFERENCES "CANAL"(id_canal)
);

CREATE TABLE "CLIENTE_NATURAL" (
    id_cliente INTEGER PRIMARY KEY,
    primer_nombre VARCHAR(50) NOT NULL,
    inicial_seg_nombre VARCHAR(50),
    apellido VARCHAR(50) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    ocupacion VARCHAR(100),
    CONSTRAINT fk_cnatural_cliente FOREIGN KEY (id_cliente) REFERENCES "CLIENTE"(id_cliente) ON DELETE CASCADE
);

CREATE TABLE "CLIENTE_JURIDICO" (
    id_cliente INTEGER PRIMARY KEY,
    nombre_org VARCHAR(100) NOT NULL,
    tipo_org VARCHAR(50) NOT NULL,
    actividad VARCHAR(100) NOT NULL,
    fecha_constitucion DATE NOT NULL,
    CONSTRAINT chk_tipo_org CHECK (tipo_org IN ('C.A.', 'S.A.', 'S.R.L.', 'Firma Personal', 'Cooperativa', 'Gubernamental')),
    CONSTRAINT fk_cjuridico_cliente FOREIGN KEY (id_cliente) REFERENCES "CLIENTE"(id_cliente) ON DELETE CASCADE
);

--- MODIFICACIÓN BCNF (1.1): VALIDACION KYC LIMPIA ---
-- Se eliminó tipo_documento. Ahora depende directamente de DOCUMENTO_IDENTIDAD
CREATE TABLE "VALIDACION_KYC" (
    id_validacion SERIAL PRIMARY KEY,
    id_cliente INTEGER NOT NULL UNIQUE,
    nivel_riesgo VARCHAR(20) NOT NULL,
    estado_pep BOOLEAN NOT NULL DEFAULT false,
    fecha_ultima_revision DATE NOT NULL,
    origen_fondos VARCHAR(100) NOT NULL,
    numero_documento VARCHAR(20) NOT NULL UNIQUE,
    fecha_vencimiento_doc DATE NOT NULL,
    huella VARCHAR(255),
    foto VARCHAR(255),
    CONSTRAINT fk_kyc_documento FOREIGN KEY (numero_documento) REFERENCES "DOCUMENTO_IDENTIDAD"(nro_documento),
    CONSTRAINT fk_kyc_cliente FOREIGN KEY (id_cliente) REFERENCES "CLIENTE"(id_cliente) ON DELETE CASCADE
);

CREATE TABLE "EMAIL" (
    direccion_email VARCHAR(100) PRIMARY KEY,
    id_cliente INTEGER NOT NULL,
    verificado BOOLEAN NOT NULL DEFAULT false,
    es_principal BOOLEAN NOT NULL DEFAULT false,
    CONSTRAINT chk_formato_email CHECK (direccion_email ~ '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT fk_email_cliente FOREIGN KEY (id_cliente) REFERENCES "CLIENTE"(id_cliente) ON DELETE CASCADE
);

CREATE TABLE "TELEFONO" (
    numero VARCHAR(20) PRIMARY KEY,
    id_cliente INTEGER NOT NULL,
    fecha_verificacion TIMESTAMP,
    verificado BOOLEAN NOT NULL DEFAULT false,
    tipo VARCHAR(20) NOT NULL,
    es_principal BOOLEAN NOT NULL DEFAULT false,
    CONSTRAINT chk_tipo_telefono CHECK (tipo IN ('Movil', 'Fijo')),
    CONSTRAINT fk_telefono_cliente FOREIGN KEY (id_cliente) REFERENCES "CLIENTE"(id_cliente) ON DELETE CASCADE
);

CREATE TABLE "AFILIACION_CANAL" (
    id_cliente INTEGER NOT NULL,
    tipo_canal VARCHAR(50) NOT NULL,
    fecha_afiliacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado_acceso VARCHAR(20) NOT NULL DEFAULT 'activo',
    PRIMARY KEY (id_cliente, tipo_canal),
    CONSTRAINT chk_tipo_canal_afil CHECK (tipo_canal IN ('Digital', 'Electronico')),
    CONSTRAINT fk_afil_cliente FOREIGN KEY (id_cliente) REFERENCES "CLIENTE"(id_cliente) ON DELETE CASCADE
);

--- PRODUCTOS FINANCIEROS ---
CREATE TABLE "CUENTA" (
    nro_cuenta VARCHAR(20) PRIMARY KEY,
    id_cliente INTEGER NOT NULL,
    id_canal_apertura INTEGER NOT NULL,
    tipo_cuenta VARCHAR(20) NOT NULL,
    fecha_apertura TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    saldo NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    moneda VARCHAR(3) NOT NULL DEFAULT 'VES',
    estado VARCHAR(20) NOT NULL DEFAULT 'activa',
    CONSTRAINT chk_tipo_cuenta CHECK (tipo_cuenta IN ('Ahorro', 'Corriente')),
    CONSTRAINT fk_cuenta_cliente FOREIGN KEY (id_cliente) REFERENCES "CLIENTE"(id_cliente),
    CONSTRAINT fk_cuenta_canal FOREIGN KEY (id_canal_apertura) REFERENCES "CANAL"(id_canal)
);

CREATE TABLE "CUENTA_AHORRO" (
    nro_cuenta VARCHAR(20) PRIMARY KEY,
    limite_diario NUMERIC(15,2) NOT NULL,
    tasa_interes NUMERIC(5,2) NOT NULL,
    CONSTRAINT chk_tasa_ahorro CHECK (tasa_interes >= 0),
    CONSTRAINT fk_cahorro_cuenta FOREIGN KEY (nro_cuenta) REFERENCES "CUENTA"(nro_cuenta) ON DELETE CASCADE
);

CREATE TABLE "CUENTA_CORRIENTE" (
    nro_cuenta VARCHAR(20) PRIMARY KEY,
    limite_diario NUMERIC(15,2) NOT NULL,
    CONSTRAINT fk_ccorriente_cuenta FOREIGN KEY (nro_cuenta) REFERENCES "CUENTA"(nro_cuenta) ON DELETE CASCADE
);

CREATE TABLE "CONTRATO" (
    id_contrato SERIAL PRIMARY KEY,
    id_cliente INTEGER NOT NULL,
    nro_cuenta VARCHAR(20) NOT NULL,
    fecha TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    firma_digital VARCHAR(255) NOT NULL,
    tyc TEXT NOT NULL,
    CONSTRAINT fk_contrato_cliente FOREIGN KEY (id_cliente) REFERENCES "CLIENTE"(id_cliente) ON DELETE CASCADE,
    CONSTRAINT fk_contrato_cuenta FOREIGN KEY (nro_cuenta) REFERENCES "CUENTA"(nro_cuenta) ON DELETE CASCADE
);

CREATE TABLE "DOMICILIACION_CUENTA" (
    nro_cuenta VARCHAR(20),
    nombre_servicio VARCHAR(100),
    monto_max_debito NUMERIC(15,2) NOT NULL,
    PRIMARY KEY (nro_cuenta, nombre_servicio),
    CONSTRAINT fk_domic_cuenta FOREIGN KEY (nro_cuenta) REFERENCES "CUENTA"(nro_cuenta) ON DELETE CASCADE
);

CREATE TABLE "AFILIACION_PAGOMOVIL" (
    numero_telefono VARCHAR(20) PRIMARY KEY,
    nro_cuenta VARCHAR(20) NOT NULL,
    fecha_afiliacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_afilp2p_telefono FOREIGN KEY (numero_telefono) REFERENCES "TELEFONO"(numero) ON DELETE CASCADE,
    CONSTRAINT fk_afilp2p_cuenta FOREIGN KEY (nro_cuenta) REFERENCES "CUENTA"(nro_cuenta) ON DELETE CASCADE
);

--- ========================================================= ---
--- MODIFICACIÓN BCNF y 4FN/5FN: JERARQUÍA DE TARJETAS
--- ========================================================= ---

-- Tabla Padre TARJETA limpia (Se removieron límites, saldos y permisos)
CREATE TABLE "TARJETA" (
    nro_tarjeta VARCHAR(16) PRIMARY KEY,
    nro_cuenta VARCHAR(20) NOT NULL,
    id_canal_emisor INTEGER NOT NULL,
    tipo_tarjeta VARCHAR(20) NOT NULL,
    id_marca INTEGER NOT NULL,
    nro_tarjeta_previa VARCHAR(16),
    motivo_emision VARCHAR(50),
    formato_tarjeta VARCHAR(20) NOT NULL,
    clave_tarjeta VARCHAR(255) NOT NULL,
    fecha_expiracion DATE NOT NULL,
    cvv VARCHAR(4) NOT NULL,
    intentos_fallidos INTEGER NOT NULL DEFAULT 0,
    estado VARCHAR(20) NOT NULL DEFAULT 'activa',
    CONSTRAINT chk_tipo_tarjeta CHECK (tipo_tarjeta IN ('Debito', 'Credito')),
    CONSTRAINT fk_tarjeta_cuenta FOREIGN KEY (nro_cuenta) REFERENCES "CUENTA"(nro_cuenta),
    CONSTRAINT fk_tarjeta_canal FOREIGN KEY (id_canal_emisor) REFERENCES "CANAL"(id_canal),
    CONSTRAINT fk_tarjeta_marca FOREIGN KEY (id_marca) REFERENCES "MARCA"(id_marca),
    CONSTRAINT fk_tarjeta_previa FOREIGN KEY (nro_tarjeta_previa) REFERENCES "TARJETA"(nro_tarjeta) ON DELETE SET NULL
);

-- Subclase Débito (1.1 BCNF)
CREATE TABLE "TARJETA_DEBITO" (
    nro_tarjeta VARCHAR(16) PRIMARY KEY,
    fondo_asociado VARCHAR(50) NOT NULL,
    CONSTRAINT fk_tdebito_tarjeta FOREIGN KEY (nro_tarjeta) REFERENCES "TARJETA"(nro_tarjeta) ON DELETE CASCADE
);

-- Subclase Crédito (1.1 BCNF)
CREATE TABLE "TARJETA_CREDITO" (
    nro_tarjeta VARCHAR(16) PRIMARY KEY,
    fondo_asociado VARCHAR(50) NOT NULL,
    saldo_consumido NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    limite_credito NUMERIC(15,2) NOT NULL,
    tasa_interes NUMERIC(5,2) NOT NULL,
    fecha_corte DATE NOT NULL,
    CONSTRAINT fk_tcredito_tarjeta FOREIGN KEY (nro_tarjeta) REFERENCES "TARJETA"(nro_tarjeta) ON DELETE CASCADE
);

-- Extracción de Dependencias Multivaluadas (1.2 4FN/5FN)
CREATE TABLE "PERMISOS_TARJETA" (
    nro_tarjeta VARCHAR(16) PRIMARY KEY,
    permiso_ecommerce BOOLEAN NOT NULL DEFAULT false,
    permiso_internacional BOOLEAN NOT NULL DEFAULT false,
    CONSTRAINT fk_permisos_tarjeta FOREIGN KEY (nro_tarjeta) REFERENCES "TARJETA"(nro_tarjeta) ON DELETE CASCADE
);

--- TRANSACCIONES ---
CREATE TABLE "MOVIMIENTO" (
    nro_referencia VARCHAR(50) PRIMARY KEY,
    id_tipo_mov INTEGER NOT NULL,
    id_canal INTEGER NOT NULL,
    id_banco_origen INTEGER NOT NULL,
    id_banco_destino INTEGER NOT NULL,
    nro_cuenta_origen VARCHAR(20) NOT NULL,
    nro_cuenta_destino VARCHAR(20) NOT NULL,
    descripcion_mov VARCHAR(255) NOT NULL,
    monto_ingreso NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    monto_egreso NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    monto_comision NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    estado VARCHAR(20) NOT NULL,
    fecha TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    saldo_origen_previo NUMERIC(15,2) NOT NULL,
    saldo_origen_nuevo NUMERIC(15,2) NOT NULL,
    saldo_destino_previo NUMERIC(15,2),
    saldo_destino_nuevo NUMERIC(15,2),
    ubi_transaccion VARCHAR(255),

    CONSTRAINT fk_mov_tipo FOREIGN KEY (id_tipo_mov) REFERENCES "TIPO_MOVIMIENTO"(id_tipo_mov),
    CONSTRAINT fk_mov_canal FOREIGN KEY (id_canal) REFERENCES "CANAL"(id_canal),
    CONSTRAINT fk_mov_banco_origen FOREIGN KEY (id_banco_origen) REFERENCES "BANCO"(id_banco),
    CONSTRAINT fk_mov_banco_destino FOREIGN KEY (id_banco_destino) REFERENCES "BANCO"(id_banco),
    CONSTRAINT chk_mov_cuentas_distintas CHECK (nro_cuenta_origen <> nro_cuenta_destino)
);

CREATE TABLE "MOVIMIENTO_PAGO_POS" (
    nro_referencia VARCHAR(50) PRIMARY KEY,
    nro_tarjeta VARCHAR(16) NOT NULL,
    CONSTRAINT fk_mpos_movimiento FOREIGN KEY (nro_referencia) REFERENCES "MOVIMIENTO"(nro_referencia) ON DELETE CASCADE,
    CONSTRAINT fk_mpos_tarjeta FOREIGN KEY (nro_tarjeta) REFERENCES "TARJETA"(nro_tarjeta)
);

CREATE TABLE "MOVIMIENTO_PAGO_ECOMMERCE" (
    nro_referencia VARCHAR(50) PRIMARY KEY,
    nro_tarjeta VARCHAR(16) NOT NULL,
    pagina_web VARCHAR(255) NOT NULL,
    CONSTRAINT fk_mecom_movimiento FOREIGN KEY (nro_referencia) REFERENCES "MOVIMIENTO"(nro_referencia) ON DELETE CASCADE,
    CONSTRAINT fk_mecom_tarjeta FOREIGN KEY (nro_tarjeta) REFERENCES "TARJETA"(nro_tarjeta)
);

CREATE TABLE "MOVIMIENTO_RETIRO_ATM" (
    nro_referencia VARCHAR(50) PRIMARY KEY,
    nro_tarjeta VARCHAR(16) NOT NULL,
    CONSTRAINT fk_matm_movimiento FOREIGN KEY (nro_referencia) REFERENCES "MOVIMIENTO"(nro_referencia) ON DELETE CASCADE,
    CONSTRAINT fk_matm_tarjeta FOREIGN KEY (nro_tarjeta) REFERENCES "TARJETA"(nro_tarjeta)
);

CREATE TABLE "MOVIMIENTO_TRANSFERENCIA" (
    nro_referencia VARCHAR(50) PRIMARY KEY,
    medio VARCHAR(50) NOT NULL,
    CONSTRAINT fk_mtransf_movimiento FOREIGN KEY (nro_referencia) REFERENCES "MOVIMIENTO"(nro_referencia) ON DELETE CASCADE
);

CREATE TABLE "MOVIMIENTO_PAGOMOVIL" (
    nro_referencia VARCHAR(50) PRIMARY KEY,
    pm_telefono VARCHAR(20) NOT NULL,
    pm_ci VARCHAR(20) NOT NULL,
    CONSTRAINT fk_mpagomovil_movimiento FOREIGN KEY (nro_referencia) REFERENCES "MOVIMIENTO"(nro_referencia) ON DELETE CASCADE
);

-- ==============================================================================
-- MÓDULO DE AUDITORÍA Y LIMPIEZA (Adaptado a Esquema usb_bank BCNF/5FN)
-- ==============================================================================
SET search_path TO "usb_bank";

-- 1. CORRECCIÓN DE BORRADOS EN CASCADA
ALTER TABLE "CUENTA" DROP CONSTRAINT IF EXISTS fk_cuenta_cliente;
ALTER TABLE "CUENTA" ADD CONSTRAINT fk_cuenta_cliente FOREIGN KEY (id_cliente) REFERENCES "CLIENTE"(id_cliente) ON DELETE CASCADE;

ALTER TABLE "TARJETA" DROP CONSTRAINT IF EXISTS fk_tarjeta_cuenta;
ALTER TABLE "TARJETA" ADD CONSTRAINT fk_tarjeta_cuenta FOREIGN KEY (nro_cuenta) REFERENCES "CUENTA"(nro_cuenta) ON DELETE CASCADE;

ALTER TABLE "MOVIMIENTO_PAGO_POS" DROP CONSTRAINT IF EXISTS fk_mpos_tarjeta;
ALTER TABLE "MOVIMIENTO_PAGO_POS" ADD CONSTRAINT fk_mpos_tarjeta FOREIGN KEY (nro_tarjeta) REFERENCES "TARJETA"(nro_tarjeta) ON DELETE CASCADE;

ALTER TABLE "MOVIMIENTO_PAGO_ECOMMERCE" DROP CONSTRAINT IF EXISTS fk_mecom_tarjeta;
ALTER TABLE "MOVIMIENTO_PAGO_ECOMMERCE" ADD CONSTRAINT fk_mecom_tarjeta FOREIGN KEY (nro_tarjeta) REFERENCES "TARJETA"(nro_tarjeta) ON DELETE CASCADE;

ALTER TABLE "MOVIMIENTO_RETIRO_ATM" DROP CONSTRAINT IF EXISTS fk_matm_tarjeta;
ALTER TABLE "MOVIMIENTO_RETIRO_ATM" ADD CONSTRAINT fk_matm_tarjeta FOREIGN KEY (nro_tarjeta) REFERENCES "TARJETA"(nro_tarjeta) ON DELETE CASCADE;

-- 2. TABLA DE AUDITORÍA
CREATE TABLE IF NOT EXISTS "REPORTE_CLIENTES_ELIMINADOS" (
    id_reporte SERIAL PRIMARY KEY,
    fecha_eliminacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    id_cliente INTEGER NOT NULL,
    doc_cliente VARCHAR(30),
    nombre_cliente VARCHAR(150) NOT NULL,
    cantidad_cuentas INTEGER NOT NULL DEFAULT 0
);

-- 3. FUNCIÓN Y TRIGGER
CREATE OR REPLACE FUNCTION auditar_eliminacion_cliente()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_documento VARCHAR(30); v_nombre VARCHAR(150); v_cant_cuentas INTEGER;
BEGIN
    SELECT COALESCE(k.numero_documento, OLD.rif, 'SIN DOC') INTO v_documento FROM "VALIDACION_KYC" k WHERE k.id_cliente = OLD.id_cliente;

    IF OLD.tipo_cliente = 'Natural' THEN
        SELECT COALESCE(cn.primer_nombre || ' ' || cn.apellido, 'SIN NOMBRE') INTO v_nombre FROM "CLIENTE_NATURAL" cn WHERE cn.id_cliente = OLD.id_cliente;
    ELSIF OLD.tipo_cliente = 'Juridico' THEN
        SELECT COALESCE(cj.nombre_org, 'SIN NOMBRE') INTO v_nombre FROM "CLIENTE_JURIDICO" cj WHERE cj.id_cliente = OLD.id_cliente;
    ELSE
        v_nombre := 'NO DEFINIDO';
    END IF;

    SELECT COUNT(*) INTO v_cant_cuentas FROM "CUENTA" WHERE id_cliente = OLD.id_cliente;
    INSERT INTO "REPORTE_CLIENTES_ELIMINADOS" (id_cliente, doc_cliente, nombre_cliente, cantidad_cuentas) VALUES (OLD.id_cliente, v_documento, v_nombre, v_cant_cuentas);
    RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS tr_auditar_eliminacion ON "CLIENTE";
CREATE TRIGGER tr_auditar_eliminacion BEFORE DELETE ON "CLIENTE" FOR EACH ROW EXECUTE FUNCTION auditar_eliminacion_cliente();

-- 4. STORED PROCEDURE Y CURSOR (Para la defensa técnica)
CREATE OR REPLACE PROCEDURE "sp_mostrar_clientes_eliminados"()
LANGUAGE plpgsql AS $$
DECLARE
    v_id_cliente INTEGER; v_doc_cliente VARCHAR(30); v_nombre_cliente VARCHAR(150); v_cantidad_cuentas INTEGER;
    v_total_ingresos NUMERIC(15,2) := 0; v_total_egresos NUMERIC(15,2) := 0; v_saldo_total_banco NUMERIC(15,2) := 0; v_total_clientes INTEGER := 0;
    cur_clientes CURSOR FOR SELECT id_cliente, doc_cliente, nombre_cliente, cantidad_cuentas FROM "REPORTE_CLIENTES_ELIMINADOS" ORDER BY fecha_eliminacion DESC, id_cliente;
BEGIN
    RAISE NOTICE '=== REPORTE DE CLIENTES ELIMINADOS POR INACTIVIDAD ===';
    OPEN cur_clientes;
    LOOP
        FETCH cur_clientes INTO v_id_cliente, v_doc_cliente, v_nombre_cliente, v_cantidad_cuentas;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'ID: % | DOC: % | NOMBRE: % | CUENTAS: %', LPAD(v_id_cliente::text, 4, '0'), RPAD(COALESCE(v_doc_cliente, 'N/A'), 12, ' '), RPAD(v_nombre_cliente, 25, ' '), v_cantidad_cuentas;
    END LOOP;
    CLOSE cur_clientes;

    SELECT COUNT(DISTINCT id_cliente) INTO v_total_clientes FROM "REPORTE_CLIENTES_ELIMINADOS";
    SELECT COALESCE(SUM(monto_ingreso), 0) INTO v_total_ingresos FROM "MOVIMIENTO";
    SELECT COALESCE(SUM(monto_egreso), 0) INTO v_total_egresos FROM "MOVIMIENTO";
    SELECT COALESCE(SUM(saldo), 0) INTO v_saldo_total_banco FROM "CUENTA";

    RAISE NOTICE '=== RESUMEN GENERAL DEL BANCO (POST-ELIMINACIÓN) ===';
    RAISE NOTICE 'TOTAL CLIENTES ELIMINADOS: %', v_total_clientes;
    RAISE NOTICE 'TOTAL INGRESOS REGISTRADOS: % VES', v_total_ingresos;
    RAISE NOTICE 'TOTAL EGRESOS REGISTRADOS:  % VES', v_total_egresos;
    RAISE NOTICE 'SALDO TOTAL EN BÓVEDAS:     % VES', v_saldo_total_banco;
END;
$$;
