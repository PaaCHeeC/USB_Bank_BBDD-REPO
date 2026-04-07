-- ==============================================================================
-- SCRIPT DE INSERTS DEFINITIVO (LISTO PARA LA DEFENSA)
-- Esquema: usb_bank_p09_1_N
-- ==============================================================================
-- LÓGICA DE AUDITORÍA:
-- 1. Clientes 1 al 20: Tienen fechas actuales (CURRENT_TIMESTAMP) -> SOBREVIVEN.
-- 2. Clientes 998 y 999: Tienen fechas antiguas (- 2 meses) -> SON ELIMINADOS.
-- ==============================================================================

SET search_path TO "usb_bank";

--- 1. CATALOGOS BASE ---
INSERT INTO "BANCO" (id_banco, nombre_banco) VALUES
(1, 'USB Bank'), (2, 'Banco Nacional del Caribe'), (3, 'Banco Capital Uno'),
(4, 'Banco Horizonte'), (5, 'Banco Delta Financiero'), (6, 'Banco Plaza Central'),
(7, 'Banco del Sol'), (8, 'Banco Metropolitano'), (9, 'Banco Andino'),
(10, 'Banco Universal Digital')
ON CONFLICT DO NOTHING;

INSERT INTO "MARCA" (id_marca, nombre_marca, bin) VALUES
(1, 'Visa', '401234'), (2, 'Mastercard', '512345'), (3, 'Maestro', '639876'),
(4, 'American Express', '371245'), (5, 'Cabal', '604321'), (6, 'Cirrus', '567890')
ON CONFLICT DO NOTHING;

INSERT INTO "TIPO_MOVIMIENTO" (id_tipo_mov, descripcion) VALUES
(1, 'Transferencia entre cuentas'), (2, 'Pago por punto de venta'),
(3, 'Pago por ecommerce'), (4, 'Retiro en cajero automatico'),
(5, 'Pago Movil'), (6, 'Transferencia interbancaria')
ON CONFLICT DO NOTHING;

INSERT INTO "TIPO_DOCUMENTO" (id_tipo_doc, descripcion) VALUES
('V', 'Cedula de identidad'), ('E', 'Cedula de extranjero'),
('J', 'RIF juridico'), ('P', 'Pasaporte'), ('G', 'Documento gubernamental')
ON CONFLICT DO NOTHING;

--- 2. CANALES ---
INSERT INTO "CANAL" (id_canal, tipo_canal, descripcion) VALUES
(1, 'Digital', 'Portal web personas'), (2, 'Digital', 'Portal web empresas'),
(3, 'Digital', 'Portal web premium'), (4, 'Digital', 'Portal web onboarding'),
(5, 'Digital', 'Portal web comercio'), (6, 'Digital', 'App movil personas'),
(7, 'Digital', 'App movil empresas'), (8, 'Digital', 'App movil premium'),
(9, 'Digital', 'App movil onboarding'), (10, 'Digital', 'App movil pagos'),
(11, 'Electronico', 'ATM Sede Caracas'), (12, 'Electronico', 'ATM Sede Valencia'),
(13, 'Electronico', 'ATM Sede Maracaibo'), (14, 'Electronico', 'ATM Sede Barquisimeto'),
(15, 'Electronico', 'POS Comercios Caracas'), (16, 'Electronico', 'POS Comercios Valencia'),
(17, 'Electronico', 'POS Comercios Maracaibo'), (18, 'Electronico', 'IVR Atencion General'),
(19, 'Electronico', 'IVR Tarjetas'), (20, 'Electronico', 'IVR Creditos')
ON CONFLICT DO NOTHING;

INSERT INTO "CANAL_DIGITAL" (id_canal, plataforma) VALUES
(1, 'Web'), (2, 'Web'), (3, 'Web'), (4, 'Web'), (5, 'Web'),
(6, 'iOS/Android'), (7, 'iOS/Android'), (8, 'iOS/Android'), (9, 'iOS/Android'), (10, 'iOS/Android')
ON CONFLICT DO NOTHING;

INSERT INTO "CANAL_WEB" (id_canal, url) VALUES
(1, 'https://personas.usbbank.com'), (2, 'https://empresas.usbbank.com'),
(3, 'https://premium.usbbank.com'), (4, 'https://onboarding.usbbank.com'),
(5, 'https://comercios.usbbank.com')
ON CONFLICT DO NOTHING;

INSERT INTO "CANAL_APP_MOVIL" (id_canal, nfc) VALUES
(6, true), (7, true), (8, true), (9, false), (10, true)
ON CONFLICT DO NOTHING;

INSERT INTO "CANAL_ELECTRONICO" (id_canal) VALUES
(11), (12), (13), (14), (15), (16), (17), (18), (19), (20)
ON CONFLICT DO NOTHING;

INSERT INTO "CANAL_POS" (id_canal, id_pos) VALUES
(15, 'POS-CCS-001'), (16, 'POS-VLC-001'), (17, 'POS-MCB-001')
ON CONFLICT DO NOTHING;

INSERT INTO "CANAL_IVR" (id_canal, id_ivr) VALUES
(18, 'IVR-GEN-001'), (19, 'IVR-TDC-001'), (20, 'IVR-CRD-001')
ON CONFLICT DO NOTHING;

--- ============================================================================== ---
--- 3. CLIENTES REALES (ESTOS VAN A SOBREVIVIR - FECHA ACTUAL)
--- ============================================================================== ---
INSERT INTO "CLIENTE" (
    id_cliente, tipo_cliente, id_canal_onboarding, fecha_registro, usuario, clave, direccion, estado, rif
) VALUES
(1, 'Natural', 4, CURRENT_TIMESTAMP, 'mruiz01', 'hash_clave_001', 'Caracas, Chacao, Calle Sucre', 'activo', NULL),
(2, 'Natural', 9, CURRENT_TIMESTAMP, 'cfernandez02', 'hash_clave_002', 'Valencia, Av. Bolivar Norte', 'activo', NULL),
(3, 'Natural', 4, CURRENT_TIMESTAMP, 'jmedina03', 'hash_clave_003', 'Maracay, Urb. Calicanto', 'activo', NULL),
(4, 'Natural', 9, CURRENT_TIMESTAMP, 'agomez04', 'hash_clave_004', 'Barquisimeto, Av. Lara', 'activo', NULL),
(5, 'Natural', 4, CURRENT_TIMESTAMP, 'lortega05', 'hash_clave_005', 'Puerto La Cruz, Lecheria', 'activo', NULL),
(6, 'Natural', 9, CURRENT_TIMESTAMP, 'dperez06', 'hash_clave_006', 'Caracas, El Paraiso', 'activo', NULL),
(7, 'Natural', 4, CURRENT_TIMESTAMP, 'sramirez07', 'hash_clave_007', 'Maturin, Centro', 'activo', NULL),
(8, 'Natural', 9, CURRENT_TIMESTAMP, 'fgarcia08', 'hash_clave_008', 'Merida, Av. Las Americas', 'activo', NULL),
(9, 'Natural', 4, CURRENT_TIMESTAMP, 'npineda09', 'hash_clave_009', 'San Cristobal, Barrio Obrero', 'activo', NULL),
(10, 'Natural', 9, CURRENT_TIMESTAMP, 'rlopez10', 'hash_clave_010', 'Caracas, La California', 'activo', NULL),
(11, 'Natural', 4, CURRENT_TIMESTAMP, 'vcastro11', 'hash_clave_011', 'Valencia, Prebo', 'activo', NULL),
(12, 'Natural', 9, CURRENT_TIMESTAMP, 'hpalma12', 'hash_clave_012', 'Maracaibo, La Lago', 'activo', NULL),
(13, 'Juridico', 2, CURRENT_TIMESTAMP, 'alfa_consulting', 'hash_clave_013', 'Caracas, Torre Financiera Alfa', 'activo', 'J-40100013-1'),
(14, 'Juridico', 2, CURRENT_TIMESTAMP, 'nova_import', 'hash_clave_014', 'Valencia, Zona Industrial', 'activo', 'J-40100014-2'),
(15, 'Juridico', 2, CURRENT_TIMESTAMP, 'orion_logistica', 'hash_clave_015', 'Maracay, Calle Comercio', 'activo', 'J-40100015-3'),
(16, 'Juridico', 2, CURRENT_TIMESTAMP, 'cacao_global', 'hash_clave_016', 'Barquisimeto, Zona Este', 'activo', 'J-40100016-4'),
(17, 'Juridico', 2, CURRENT_TIMESTAMP, 'tecnored_ca', 'hash_clave_017', 'Caracas, Los Palos Grandes', 'activo', 'J-40100017-5'),
(18, 'Juridico', 2, CURRENT_TIMESTAMP, 'agroinsumos_llano', 'hash_clave_018', 'Acarigua, Av. Principal', 'activo', 'J-40100018-6'),
(19, 'Juridico', 2, CURRENT_TIMESTAMP, 'soluciones_medicas', 'hash_clave_019', 'Caracas, Bello Monte', 'activo', 'J-40100019-7'),
(20, 'Juridico', 2, CURRENT_TIMESTAMP, 'grupolitoral', 'hash_clave_020', 'Puerto Ordaz, Alta Vista', 'activo', 'J-40100020-8')
ON CONFLICT (id_cliente) DO NOTHING;

INSERT INTO "CLIENTE_NATURAL" (id_cliente, primer_nombre, inicial_seg_nombre, apellido, fecha_nacimiento, ocupacion) VALUES
(1, 'Miguel', 'A', 'Ruiz', '1995-03-15', 'Ingeniero'), (2, 'Carla', 'M', 'Fernandez', '1998-07-21', 'Diseñadora'),
(3, 'Jose', 'L', 'Medina', '1993-11-02', 'Contador'), (4, 'Andrea', 'P', 'Gomez', '1997-05-30', 'Abogada'),
(5, 'Luis', 'E', 'Ortega', '1992-09-12', 'Arquitecto'), (6, 'Daniela', 'R', 'Perez', '1999-01-17', 'Medico'),
(7, 'Sofia', 'I', 'Ramirez', '1996-06-25', 'Administradora'), (8, 'Fabian', 'J', 'Garcia', '1991-12-08', 'Programador'),
(9, 'Natalia', 'C', 'Pineda', '1994-04-19', 'Docente'), (10, 'Ricardo', 'T', 'Lopez', '1989-08-03', 'Comerciante'),
(11, 'Valentina', 'S', 'Castro', '1997-10-14', 'Analista'), (12, 'Hector', 'D', 'Palma', '1990-02-27', 'Consultor')
ON CONFLICT DO NOTHING;

INSERT INTO "CLIENTE_JURIDICO" (id_cliente, nombre_org, tipo_org, actividad, fecha_constitucion) VALUES
(13, 'Alfa Consulting', 'C.A.', 'Consultoria empresarial', '2018-04-10'), (14, 'Nova Import', 'S.A.', 'Importacion de repuestos', '2016-09-22'),
(15, 'Orion Logistica', 'C.A.', 'Servicios logisticos', '2020-01-15'), (16, 'Cacao Global', 'S.R.L.', 'Exportacion de cacao', '2017-06-18'),
(17, 'TecnoRed', 'C.A.', 'Servicios de tecnologia', '2019-03-12'), (18, 'Agroinsumos Llano', 'Cooperativa', 'Distribucion agricola', '2015-11-05'),
(19, 'Soluciones Medicas Integrales', 'C.A.', 'Equipos medicos', '2021-07-08'), (20, 'Grupo Litoral', 'Firma Personal', 'Servicios comerciales', '2014-02-27')
ON CONFLICT DO NOTHING;

-- DOCUMENTOS IDENTIDAD (BCNF Aplicada)
INSERT INTO "DOCUMENTO_IDENTIDAD" (nro_documento, id_tipo_doc) VALUES
('V12345001', 'V'), ('V12345002', 'V'), ('V12345003', 'V'), ('V12345004', 'V'),
('V12345005', 'V'), ('V12345006', 'V'), ('V12345007', 'V'), ('V12345008', 'V'),
('V12345009', 'V'), ('V12345010', 'V'), ('V12345011', 'V'), ('V12345012', 'V'),
('J401000131', 'J'), ('J401000142', 'J'), ('J401000153', 'J'), ('J401000164', 'J'),
('J401000175', 'J'), ('J401000186', 'J'), ('J401000197', 'J'), ('J401000208', 'J')
ON CONFLICT DO NOTHING;

INSERT INTO "VALIDACION_KYC" (
    id_validacion, id_cliente, nivel_riesgo, estado_pep, fecha_ultima_revision,
    origen_fondos, numero_documento, fecha_vencimiento_doc, huella, foto
) VALUES
(1, 1, 'Bajo', false, CURRENT_DATE, 'Salario', 'V12345001', CURRENT_DATE + INTERVAL '5 years', 'huella_001', 'foto_001.jpg'),
(2, 2, 'Bajo', false, CURRENT_DATE, 'Honorarios', 'V12345002', CURRENT_DATE + INTERVAL '5 years', 'huella_002', 'foto_002.jpg'),
(3, 3, 'Medio', false, CURRENT_DATE, 'Actividad profesional', 'V12345003', CURRENT_DATE + INTERVAL '5 years', 'huella_003', 'foto_003.jpg'),
(4, 4, 'Bajo', false, CURRENT_DATE, 'Salario', 'V12345004', CURRENT_DATE + INTERVAL '5 years', 'huella_004', 'foto_004.jpg'),
(5, 5, 'Medio', false, CURRENT_DATE, 'Consultoria', 'V12345005', CURRENT_DATE + INTERVAL '5 years', 'huella_005', 'foto_005.jpg'),
(6, 6, 'Bajo', false, CURRENT_DATE, 'Salario', 'V12345006', CURRENT_DATE + INTERVAL '5 years', 'huella_006', 'foto_006.jpg'),
(7, 7, 'Bajo', false, CURRENT_DATE, 'Actividad independiente', 'V12345007', CURRENT_DATE + INTERVAL '5 years', 'huella_007', 'foto_007.jpg'),
(8, 8, 'Medio', false, CURRENT_DATE, 'Servicios profesionales', 'V12345008', CURRENT_DATE + INTERVAL '5 years', 'huella_008', 'foto_008.jpg'),
(9, 9, 'Bajo', false, CURRENT_DATE, 'Salario', 'V12345009', CURRENT_DATE + INTERVAL '5 years', 'huella_009', 'foto_009.jpg'),
(10, 10, 'Alto', false, CURRENT_DATE, 'Comercio', 'V12345010', CURRENT_DATE + INTERVAL '5 years', 'huella_010', 'foto_010.jpg'),
(11, 11, 'Bajo', false, CURRENT_DATE, 'Salario', 'V12345011', CURRENT_DATE + INTERVAL '5 years', 'huella_011', 'foto_011.jpg'),
(12, 12, 'Medio', false, CURRENT_DATE, 'Consultoria', 'V12345012', CURRENT_DATE + INTERVAL '5 years', 'huella_012', 'foto_012.jpg'),
(13, 13, 'Medio', false, CURRENT_DATE, 'Servicios corporativos', 'J401000131', CURRENT_DATE + INTERVAL '5 years', 'huella_013', 'foto_013.jpg'),
(14, 14, 'Alto', false, CURRENT_DATE, 'Importaciones', 'J401000142', CURRENT_DATE + INTERVAL '5 years', 'huella_014', 'foto_014.jpg'),
(15, 15, 'Medio', false, CURRENT_DATE, 'Operaciones logisticas', 'J401000153', CURRENT_DATE + INTERVAL '5 years', 'huella_015', 'foto_015.jpg'),
(16, 16, 'Medio', false, CURRENT_DATE, 'Exportaciones', 'J401000164', CURRENT_DATE + INTERVAL '5 years', 'huella_016', 'foto_016.jpg'),
(17, 17, 'Bajo', false, CURRENT_DATE, 'Servicios TI', 'J401000175', CURRENT_DATE + INTERVAL '5 years', 'huella_017', 'foto_017.jpg'),
(18, 18, 'Medio', false, CURRENT_DATE, 'Actividad agricola', 'J401000186', CURRENT_DATE + INTERVAL '5 years', 'huella_018', 'foto_018.jpg'),
(19, 19, 'Medio', false, CURRENT_DATE, 'Venta de equipos medicos', 'J401000197', CURRENT_DATE + INTERVAL '5 years', 'huella_019', 'foto_019.jpg'),
(20, 20, 'Bajo', false, CURRENT_DATE, 'Actividad comercial', 'J401000208', CURRENT_DATE + INTERVAL '5 years', 'huella_020', 'foto_020.jpg')
ON CONFLICT DO NOTHING;

--- ============================================================================== ---
--- 4. CLIENTES DE DEMOSTRACIÓN (ESTOS VAN A MORIR - FECHA ANTIGUA)
--- ============================================================================== ---
-- CLIENTE (Fecha registro antigua para que pase la Condición A del Trigger)
INSERT INTO "CLIENTE" (id_cliente, tipo_cliente, id_canal_onboarding, fecha_registro, usuario, clave, direccion, estado, rif) 
VALUES 
(998, 'Natural', 1, CURRENT_DATE - INTERVAL '2 months', 'inactivo_demo1', 'hash_test', 'Direccion Prueba 1', 'activo', 'V-99888777'),
(999, 'Natural', 1, CURRENT_DATE - INTERVAL '2 months', 'inactivo_demo2', 'hash_test', 'Direccion Prueba 2', 'activo', 'V-99888778')
ON CONFLICT (id_cliente) DO NOTHING;

-- CLIENTE_NATURAL
INSERT INTO "CLIENTE_NATURAL" (id_cliente, primer_nombre, inicial_seg_nombre, apellido, fecha_nacimiento, ocupacion) 
VALUES 
(998, 'Usuario', '1', 'Eliminar 1', '1990-01-01', 'Prueba Demo'),
(999, 'Usuario', '2', 'Eliminar 2', '1990-01-01', 'Prueba Demo')
ON CONFLICT (id_cliente) DO NOTHING;

-- DOCUMENTO IDENTIDAD
INSERT INTO "DOCUMENTO_IDENTIDAD" (nro_documento, id_tipo_doc) 
VALUES ('99888777', 'V'), ('99888778', 'V')
ON CONFLICT DO NOTHING;

-- KYC
INSERT INTO "VALIDACION_KYC" (id_validacion, id_cliente, nivel_riesgo, estado_pep, fecha_ultima_revision, origen_fondos, numero_documento, fecha_vencimiento_doc) 
VALUES 
(21, 998, 'Bajo', false, CURRENT_DATE, 'Ahorros', '99888777', CURRENT_DATE + INTERVAL '5 years'),
(22, 999, 'Bajo', false, CURRENT_DATE, 'Ahorros', '99888778', CURRENT_DATE + INTERVAL '5 years')
ON CONFLICT (id_cliente) DO NOTHING;


--- ============================================================================== ---
--- 5. CUENTAS BANCARIAS Y TARJETAS
--- ============================================================================== ---

INSERT INTO "CUENTA" (
    nro_cuenta, id_cliente, id_canal_apertura, tipo_cuenta, fecha_apertura,
    saldo, limite_diario, tasa_interes, moneda, estado
) VALUES
('01010000000000000001', 1, 1, 'Ahorro', CURRENT_TIMESTAMP, 1500.00, 2000.00, 2.50, 'VES', 'activa'),
('01010000000000000002', 2, 6, 'Ahorro', CURRENT_TIMESTAMP, 2300.00, 2500.00, 2.50, 'VES', 'activa'),
('01010000000000000003', 3, 1, 'Corriente', CURRENT_TIMESTAMP, 5200.00, 5000.00, 0.00, 'VES', 'activa'),
('01010000000000000004', 4, 6, 'Ahorro', CURRENT_TIMESTAMP, 3100.00, 3000.00, 2.50, 'VES', 'activa'),
('01010000000000000005', 5, 1, 'Corriente', CURRENT_TIMESTAMP, 6400.00, 6000.00, 0.00, 'VES', 'activa'),
('01010000000000000006', 6, 6, 'Ahorro', CURRENT_TIMESTAMP, 1800.00, 2500.00, 2.50, 'VES', 'activa'),
('01010000000000000007', 7, 1, 'Ahorro', CURRENT_TIMESTAMP, 2750.00, 2500.00, 2.50, 'VES', 'activa'),
('01010000000000000008', 8, 6, 'Corriente', CURRENT_TIMESTAMP, 7100.00, 7000.00, 0.00, 'VES', 'activa'),
('01010000000000000009', 9, 1, 'Ahorro', CURRENT_TIMESTAMP, 1950.00, 2200.00, 2.50, 'VES', 'activa'),
('01010000000000000010', 10, 6, 'Corriente', CURRENT_TIMESTAMP, 8400.00, 8000.00, 0.00, 'VES', 'activa'),
('01010000000000000011', 11, 1, 'Ahorro', CURRENT_TIMESTAMP, 2650.00, 2400.00, 2.50, 'VES', 'activa'),
('01010000000000000012', 12, 6, 'Corriente', CURRENT_TIMESTAMP, 9200.00, 8500.00, 0.00, 'VES', 'activa'),
('01010000000000000013', 13, 2, 'Corriente', CURRENT_TIMESTAMP, 25000.00, 15000.00, 0.00, 'VES', 'activa'),
('01010000000000000014', 14, 2, 'Corriente', CURRENT_TIMESTAMP, 31500.00, 18000.00, 0.00, 'VES', 'activa'),
('01010000000000000015', 15, 2, 'Corriente', CURRENT_TIMESTAMP, 27800.00, 17000.00, 0.00, 'VES', 'activa'),
('01010000000000000016', 16, 2, 'Corriente', CURRENT_TIMESTAMP, 33400.00, 20000.00, 0.00, 'VES', 'activa'),
('01010000000000000017', 17, 2, 'Corriente', CURRENT_TIMESTAMP, 28900.00, 16000.00, 0.00, 'VES', 'activa'),
('01010000000000000018', 18, 2, 'Corriente', CURRENT_TIMESTAMP, 22600.00, 14000.00, 0.00, 'VES', 'activa'),
('01010000000000000019', 19, 2, 'Corriente', CURRENT_TIMESTAMP, 30100.00, 17500.00, 0.00, 'VES', 'activa'),
('01010000000000000020', 20, 2, 'Corriente', CURRENT_TIMESTAMP, 19800.00, 13000.00, 0.00, 'VES', 'activa'),
-- Cuentas de los demos a sacrificar
('0000-TEST-0000-0998', 998, 1, 'Ahorro', CURRENT_TIMESTAMP, 100.00, 1000.00, 1.00, 'VES', 'activa'),
('0000-TEST-0000-0999', 999, 1, 'Ahorro', CURRENT_TIMESTAMP, 100.00, 1000.00, 1.00, 'VES', 'activa')
ON CONFLICT DO NOTHING;

INSERT INTO "TARJETA" (
    nro_tarjeta, nro_cuenta, id_canal_emisor, tipo_tarjeta, id_marca,
    motivo_emision, formato_tarjeta, clave_tarjeta, fecha_expiracion, cvv, estado
) VALUES
('4012340000000001', '01010000000000000001', 19, 'Debito', 1, 'Emision', 'Fisica', 'pin', CURRENT_DATE + INTERVAL '3 years', '101', 'activa'),
('4012340000000002', '01010000000000000002', 19, 'Debito', 1, 'Emision', 'Fisica', 'pin', CURRENT_DATE + INTERVAL '3 years', '102', 'activa'),
('5123450000000003', '01010000000000000003', 19, 'Credito', 2, 'Emision', 'Fisica', 'pin', CURRENT_DATE + INTERVAL '3 years', '103', 'activa'),
('4012340000000004', '01010000000000000004', 19, 'Debito', 1, 'Emision', 'Fisica', 'pin', CURRENT_DATE + INTERVAL '3 years', '104', 'activa'),
('5123450000000005', '01010000000000000005', 19, 'Credito', 2, 'Emision', 'Fisica', 'pin', CURRENT_DATE + INTERVAL '3 years', '105', 'activa'),
('4012340000000006', '01010000000000000006', 19, 'Debito', 1, 'Emision', 'Virtual', 'pin', CURRENT_DATE + INTERVAL '3 years', '106', 'activa'),
('4012340000000007', '01010000000000000007', 19, 'Debito', 1, 'Emision', 'Fisica', 'pin', CURRENT_DATE + INTERVAL '3 years', '107', 'activa'),
('5123450000000008', '01010000000000000008', 19, 'Credito', 2, 'Emision', 'Fisica', 'pin', CURRENT_DATE + INTERVAL '3 years', '108', 'activa'),
('4012340000000009', '01010000000000000009', 19, 'Debito', 1, 'Emision', 'Fisica', 'pin', CURRENT_DATE + INTERVAL '3 years', '109', 'activa'),
('5123450000000010', '01010000000000000010', 19, 'Credito', 2, 'Emision', 'Fisica', 'pin', CURRENT_DATE + INTERVAL '3 years', '110', 'activa'),
('4012340000000011', '01010000000000000011', 19, 'Debito', 1, 'Emision', 'Virtual', 'pin', CURRENT_DATE + INTERVAL '3 years', '111', 'activa'),
('5123450000000012', '01010000000000000012', 19, 'Credito', 2, 'Emision', 'Fisica', 'pin', CURRENT_DATE + INTERVAL '3 years', '112', 'activa'),
('6398760000000013', '01010000000000000013', 19, 'Debito', 3, 'Emision', 'Fisica', 'pin', CURRENT_DATE + INTERVAL '3 years', '113', 'activa'),
('6398760000000014', '01010000000000000014', 19, 'Debito', 3, 'Emision', 'Fisica', 'pin', CURRENT_DATE + INTERVAL '3 years', '114', 'activa'),
('6398760000000015', '01010000000000000015', 19, 'Debito', 3, 'Emision', 'Fisica', 'pin', CURRENT_DATE + INTERVAL '3 years', '115', 'activa'),
('6398760000000016', '01010000000000000016', 19, 'Debito', 3, 'Emision', 'Fisica', 'pin', CURRENT_DATE + INTERVAL '3 years', '116', 'activa'),
('6398760000000017', '01010000000000000017', 19, 'Debito', 3, 'Emision', 'Virtual', 'pin', CURRENT_DATE + INTERVAL '3 years', '117', 'activa'),
('6398760000000018', '01010000000000000018', 19, 'Debito', 3, 'Emision', 'Fisica', 'pin', CURRENT_DATE + INTERVAL '3 years', '118', 'activa'),
('6398760000000019', '01010000000000000019', 19, 'Debito', 3, 'Emision', 'Fisica', 'pin', CURRENT_DATE + INTERVAL '3 years', '119', 'activa'),
('6398760000000020', '01010000000000000020', 19, 'Debito', 3, 'Emision', 'Fisica', 'pin', CURRENT_DATE + INTERVAL '3 years', '120', 'activa'),
-- Tarjetas de los Demos a Sacrificar (Imprescindibles para que caigan en la Condición A del Trigger)
('9999000011110998', '0000-TEST-0000-0998', 1, 'Debito', 1, 'Demo', 'Fisica', 'pin', CURRENT_DATE + INTERVAL '3 years', '123', 'activa'),
('9999000011110999', '0000-TEST-0000-0999', 1, 'Debito', 1, 'Demo', 'Fisica', 'pin', CURRENT_DATE + INTERVAL '3 years', '123', 'activa')
ON CONFLICT DO NOTHING;


--- ============================================================================== ---
--- 6. MOVIMIENTOS TRANSACCIONALES (USAN CURRENT_TIMESTAMP)
--- ============================================================================== ---
-- Esto garantiza que los clientes del 1 al 20 hayan movido su tarjeta HOY. 
-- El trigger no los tocará porque su inactividad es de 0 días.

INSERT INTO "MOVIMIENTO" (
    nro_referencia, id_tipo_mov, id_canal, id_banco_origen, id_banco_destino,
    nro_cuenta_origen, nro_cuenta_destino, descripcion_mov, monto_ingreso, monto_egreso,
    estado, fecha, saldo_origen_previo, saldo_origen_nuevo, ubi_transaccion
) VALUES
('REF0003', 2, 15, 1, 1, '01010000000000000003', '01010000000000000013', 'Pago POS', 0.00, 85.00, 'Procesado', CURRENT_TIMESTAMP, 5200.00, 5115.00, 'Caracas'),
('REF0004', 3, 1, 1, 1, '01010000000000000005', '01010000000000000014', 'Compra Ecom', 0.00, 120.00, 'Procesado', CURRENT_TIMESTAMP, 6400.00, 6280.00, 'Web'),
('REF0005', 4, 11, 1, 1, '01010000000000000006', '01010000000000000013', 'Retiro ATM', 0.00, 100.00, 'Procesado', CURRENT_TIMESTAMP, 1800.00, 1699.00, 'Caracas'),
('REF0008', 2, 16, 1, 1, '01010000000000000009', '01010000000000000015', 'Pago POS', 0.00, 40.00, 'Procesado', CURRENT_TIMESTAMP, 1950.00, 1910.00, 'San Cristobal'),
('REF0009', 3, 1, 1, 1, '01010000000000000010', '01010000000000000016', 'Compra Ecom', 0.00, 260.00, 'Procesado', CURRENT_TIMESTAMP, 8400.00, 8140.00, 'Web'),
('REF0010', 4, 12, 1, 1, '01010000000000000011', '01010000000000000014', 'Retiro ATM', 0.00, 150.00, 'Procesado', CURRENT_TIMESTAMP, 2650.00, 2499.00, 'Valencia'),
('REF0013', 2, 17, 1, 1, '01010000000000000014', '01010000000000000020', 'Pago POS', 0.00, 450.00, 'Procesado', CURRENT_TIMESTAMP, 31620.00, 31170.00, 'Valencia'),
('REF0014', 3, 2, 1, 1, '01010000000000000015', '01010000000000000019', 'Compra Ecom', 0.00, 600.00, 'Procesado', CURRENT_TIMESTAMP, 27840.00, 27240.00, 'Web'),
('REF0015', 4, 13, 1, 1, '01010000000000000016', '01010000000000000018', 'Retiro ATM', 0.00, 200.00, 'Procesado', CURRENT_TIMESTAMP, 33660.00, 33459.00, 'Maracaibo'),
('REF0019', 2, 15, 1, 1, '01010000000000000020', '01010000000000000013', 'Pago POS', 0.00, 500.00, 'Procesado', CURRENT_TIMESTAMP, 20250.00, 19750.00, 'Puerto Ordaz'),
('REF0020', 3, 1, 1, 1, '01010000000000000001', '01010000000000000014', 'Compra Ecom', 0.00, 35.00, 'Procesado', CURRENT_TIMESTAMP, 1848.50, 1813.50, 'Web')
ON CONFLICT DO NOTHING;

INSERT INTO "MOVIMIENTO_PAGO_POS" (nro_referencia, nro_tarjeta) VALUES
('REF0003', '5123450000000003'), ('REF0008', '4012340000000009'),
('REF0013', '6398760000000014'), ('REF0019', '6398760000000020')
ON CONFLICT DO NOTHING;

INSERT INTO "MOVIMIENTO_PAGO_ECOMMERCE" (nro_referencia, nro_tarjeta, pagina_web) VALUES
('REF0004', '5123450000000005', 'www.repuestos24.com'), ('REF0009', '5123450000000010', 'www.insumospro.com'),
('REF0014', '6398760000000015', 'www.logisticashop.com'), ('REF0020', '4012340000000001', 'www.streamplus.com')
ON CONFLICT DO NOTHING;

INSERT INTO "MOVIMIENTO_RETIRO_ATM" (nro_referencia, nro_tarjeta) VALUES
('REF0005', '4012340000000006'), ('REF0010', '4012340000000011'), ('REF0015', '6398760000000016')
ON CONFLICT DO NOTHING;