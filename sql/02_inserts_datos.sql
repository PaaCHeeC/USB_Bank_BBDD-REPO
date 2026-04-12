SET search_path TO "usb_bank";

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
(19, 'Electronico', 'IVR Tarjetas'), (20, 'Electronico', 'IVR Creditos'),
(21, 'Electronico', 'POS Comercios Margarita'), (22, 'Electronico', 'POS Comercios Puerto La Cruz'),
(23, 'Electronico', 'IVR Soporte VIP'), (24, 'Electronico', 'IVR Fraudes'),
(25, 'Electronico', 'POS Comercio Zulia'), (26, 'Electronico', 'POS Comercio Andes'),
(27, 'Electronico', 'IVR Soporte Tecnico'), (28, 'Electronico', 'IVR Reclamos'),
(29, 'Electronico', 'ATM Sede Oriente')
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
(11), (12), (13), (14), (15), (16), (17), (18), (19), (20),
(21), (22), (23), (24), (25), (26), (27), (28), (29)
ON CONFLICT DO NOTHING;

INSERT INTO "CANAL_POS" (id_canal, id_pos) VALUES
(15, 'POS-CCS-001'), (16, 'POS-VLC-001'), (17, 'POS-MCB-001'),
(21, 'POS-MGT-001'), (22, 'POS-PLC-001'), (25, 'POS-ZUL-001'), (26, 'POS-AND-001')
ON CONFLICT DO NOTHING;

INSERT INTO "CANAL_IVR" (id_canal, id_ivr) VALUES
(18, 'IVR-GEN-001'), (19, 'IVR-TDC-001'), (20, 'IVR-CRD-001'),
(23, 'IVR-VIP-001'), (24, 'IVR-FRD-001'), (27, 'IVR-TEC-001'), (28, 'IVR-REC-001')
ON CONFLICT DO NOTHING;

INSERT INTO "CANAL_ATM" (id_canal, id_atm, ubicacion, efectivo_disponible) VALUES
(11, 'ATM-CCS-001', 'Sede Principal, Caracas', 50000.00),
(12, 'ATM-VAL-001', 'Metropolis, Valencia', 45000.00),
(13, 'ATM-MCB-001', 'Sambil, Maracaibo', 30000.00),
(14, 'ATM-BRQ-001', 'Las Trinitarias, Barquisimeto', 20000.00),
(29, 'ATM-ORI-001', 'C.C. Oriente, Puerto La Cruz', 45000.00)
ON CONFLICT DO NOTHING;

INSERT INTO "CLIENTE" (
    id_cliente, tipo_cliente, id_canal_onboarding, fecha_registro, usuario, clave, direccion, estado, rif
) VALUES
(1, 'Natural', 4, '2020-01-15 10:00:00', 'mruiz01', 'hash_clave_001', 'Caracas, Chacao, Calle Sucre', 'activo', NULL),
(2, 'Natural', 9, '2020-06-20 14:30:00', 'cfernandez02', 'hash_clave_002', 'Valencia, Av. Bolivar Norte', 'activo', NULL),
(3, 'Natural', 3, '2021-03-10 09:15:00', 'jmedina03', 'hash_clave_003', 'Maracay, Urb. Calicanto', 'activo', NULL),
(4, 'Natural', 9, '2021-09-05 16:45:00', 'agomez04', 'hash_clave_004', 'Barquisimeto, Av. Lara', 'activo', NULL),
(5, 'Natural', 4, '2022-02-14 11:20:00', 'lortega05', 'hash_clave_005', 'Puerto La Cruz, Lecheria', 'activo', NULL),
(6, 'Natural', 9, '2022-07-22 08:10:00', 'dperez06', 'hash_clave_006', 'Caracas, El Paraiso', 'activo', NULL),
(7, 'Natural', 4, '2023-04-11 15:55:00', 'sramirez07', 'hash_clave_007', 'Maturin, Centro', 'activo', NULL),
(8, 'Natural', 9, '2023-11-30 13:40:00', 'fgarcia08', 'hash_clave_008', 'Merida, Av. Las Americas', 'activo', NULL),
(9, 'Natural', 4, '2024-05-18 10:25:00', 'npineda09', 'hash_clave_009', 'San Cristobal, Barrio Obrero', 'activo', NULL),
(10, 'Natural', 9, '2024-12-01 09:00:00', 'rlopez10', 'hash_clave_010', 'Caracas, La California', 'activo', NULL),
(11, 'Natural', 8, '2025-01-10 08:30:00', 'vcastro11', 'hash_clave_011', 'Valencia, Prebo', 'activo', NULL),
(12, 'Natural', 9, '2025-02-28 16:00:00', 'hpalma12', 'hash_clave_012', 'Maracaibo, La Lago', 'activo', NULL),
(13, 'Juridico', 2, '2020-08-08 08:00:00', 'alfa_consulting', 'hash_clave_013', 'Caracas, Torre Financiera Alfa', 'activo', 'J-40100013-1'),
(14, 'Juridico', 2, '2021-11-11 14:00:00', 'nova_import', 'hash_clave_014', 'Valencia, Zona Industrial', 'activo', 'J-40100014-2'),
(15, 'Juridico', 2, '2022-05-05 16:30:00', 'orion_logistica', 'hash_clave_015', 'Maracay, Calle Comercio', 'activo', 'J-40100015-3'),
(16, 'Juridico', 2, '2023-09-09 10:15:00', 'cacao_global', 'hash_clave_016', 'Barquisimeto, Zona Este', 'activo', 'J-40100016-4'),
(17, 'Juridico', 5, '2024-02-02 11:45:00', 'tecnored_ca', 'hash_clave_017', 'Caracas, Los Palos Grandes', 'activo', 'J-40100017-5'),
(18, 'Juridico', 2, '2024-08-15 09:30:00', 'agroinsumos_llano', 'hash_clave_018', 'Acarigua, Av. Principal', 'activo', 'J-40100018-6'),
(19, 'Juridico', 2, '2025-03-01 10:00:00', 'soluciones_medicas', 'hash_clave_019', 'Caracas, Bello Monte', 'activo', 'J-40100019-7'),
(20, 'Juridico', 2, '2025-04-10 11:00:00', 'grupolitoral', 'hash_clave_020', 'Puerto Ordaz, Alta Vista', 'activo', 'J-40100020-8'),
(21, 'Natural', 1, '2023-12-01 10:00:00', 'rochibochhi', 'hash_clave_021', 'Caracas, Bello Monte', 'activo', NULL),
(998, 'Natural', 1, '2023-12-01 10:00:00', 'inactivo1', 'test', 'Test 1', 'activo', 'V-99888777'),
(999, 'Natural', 1, '2023-12-01 10:00:00', 'inactivo2', 'test', 'Test 2', 'activo', 'V-99888778')
ON CONFLICT DO NOTHING;

INSERT INTO "CLIENTE_NATURAL" (id_cliente, primer_nombre, inicial_seg_nombre, apellido, fecha_nacimiento, ocupacion) VALUES
(1, 'Miguel', 'A', 'Ruiz', '1995-03-15', 'Ingeniero'), (2, 'Carla', 'M', 'Fernandez', '1998-07-21', 'Diseñadora'),
(3, 'Jose', 'L', 'Medina', '1993-11-02', 'Contador'), (4, 'Andrea', 'P', 'Gomez', '1997-05-30', 'Abogada'),
(5, 'Luis', 'E', 'Ortega', '1992-09-12', 'Arquitecto'), (6, 'Daniela', 'R', 'Perez', '1999-01-17', 'Medico'),
(7, 'Sofia', 'I', 'Ramirez', '1996-06-25', 'Administradora'), (8, 'Fabian', 'J', 'Garcia', '1991-12-08', 'Programador'),
(9, 'Natalia', 'C', 'Pineda', '1994-04-19', 'Docente'), (10, 'Ricardo', 'T', 'Lopez', '1989-08-03', 'Comerciante'),
(11, 'Valentina', 'S', 'Castro', '1997-10-14', 'Analista'), (12, 'Hector', 'D', 'Palma', '1990-02-27', 'Consultor'),
(21, 'Rosa', 'V', 'Ramirez', '1996-02-08', 'Ingeniera'),
(998, 'Ernesto', 'R', 'Guevara', '1990-01-01', 'Estudiante'), (999, 'Maria', 'F', 'Perez', '1990-01-01', 'Comerciante')
ON CONFLICT DO NOTHING;

INSERT INTO "CLIENTE_JURIDICO" (id_cliente, nombre_org, tipo_org, actividad, fecha_constitucion) VALUES
(13, 'Alfa Consulting', 'C.A.', 'Consultoria empresarial', '2018-04-10'), (14, 'Nova Import', 'S.A.', 'Importacion de repuestos', '2016-09-22'),
(15, 'Orion Logistica', 'C.A.', 'Servicios logisticos', '2020-01-15'), (16, 'Cacao Global', 'S.R.L.', 'Exportacion de cacao', '2017-06-18'),
(17, 'TecnoRed', 'C.A.', 'Servicios de tecnologia', '2019-03-12'), (18, 'Agroinsumos Llano', 'Cooperativa', 'Distribucion agricola', '2015-11-05'),
(19, 'Soluciones Medicas Integrales', 'C.A.', 'Equipos medicos', '2021-07-08'), (20, 'Gobernacion Litoral', 'Gubernamental', 'Servicios publicos', '2014-02-27')
ON CONFLICT DO NOTHING;

INSERT INTO "DOCUMENTO_IDENTIDAD" (nro_documento, id_tipo_doc) VALUES
('V12345001', 'V'), ('V12345002', 'V'), ('V12345003', 'V'), ('V12345004', 'V'),
('E84392011', 'E'), ('V12345006', 'V'), ('V12345007', 'V'), ('V12345008', 'V'),
('V12345009', 'V'), ('V12345010', 'V'), ('V12345011', 'V'), ('P99302112', 'P'),
('J401000131', 'J'), ('J401000142', 'J'), ('J401000153', 'J'), ('J401000164', 'J'),
('J401000175', 'J'), ('J401000186', 'J'), ('J401000197', 'J'), ('G401000208', 'G'),
('99888777', 'V'), ('99888778', 'V')
ON CONFLICT DO NOTHING;

INSERT INTO "VALIDACION_KYC" (
    id_validacion, id_cliente, nivel_riesgo, estado_pep, fecha_ultima_revision,
    origen_fondos, numero_documento, fecha_vencimiento_doc, huella, foto
) VALUES
(1, 1, 'Bajo', false, '2025-01-01', 'Salario', 'V12345001', '2030-01-01', 'huella_001', 'foto_001.jpg'),
(2, 2, 'Bajo', false, '2025-01-01', 'Honorarios', 'V12345002', '2030-01-01', 'huella_002', 'foto_002.jpg'),
(3, 3, 'Medio', false, '2025-01-01', 'Actividad profesional', 'V12345003', '2030-01-01', 'huella_003', 'foto_003.jpg'),
(4, 4, 'Bajo', false,'2025-01-01', 'Salario', 'V12345004', '2030-01-01', 'huella_004', 'foto_004.jpg'),
(5, 5, 'Medio', false, '2025-01-01', 'Consultoria', 'E84392011', '2030-01-01', 'huella_005', 'foto_005.jpg'),
(6, 6, 'Bajo', false, '2025-01-01', 'Salario', 'V12345006', '2030-01-01', 'huella_006', 'foto_006.jpg'),
(7, 7, 'Bajo', false, '2025-01-01', 'Actividad independiente', 'V12345007', '2030-01-01', 'huella_007', 'foto_007.jpg'),
(8, 8, 'Medio', false, '2025-01-01', 'Servicios profesionales', 'V12345008', '2030-01-01', 'huella_008', 'foto_008.jpg'),
(9, 9, 'Bajo', false, '2025-01-01', 'Salario', 'V12345009', '2030-01-01', 'huella_009', 'foto_009.jpg'),
(10, 10, 'Alto', false, '2025-01-01', 'Comercio', 'V12345010', '2030-01-01', 'huella_010', 'foto_010.jpg'),
(11, 11, 'Bajo', false, '2025-01-01', 'Salario', 'V12345011', '2030-01-01', 'huella_011', 'foto_011.jpg'),
(12, 12, 'Medio', false, '2025-01-01', 'Consultoria Extranjera', 'P99302112', '2030-01-01', 'huella_012', 'foto_012.jpg'),
(13, 13, 'Medio', false, '2025-01-01', 'Servicios corporativos', 'J401000131', '2030-01-01', 'huella_013', 'foto_013.jpg'),
(14, 14, 'Alto', false, '2025-01-01', 'Importaciones', 'J401000142', '2030-01-01', 'huella_014', 'foto_014.jpg'),
(15, 15, 'Medio', false, '2025-01-01', 'Operaciones logisticas', 'J401000153', '2030-01-01', 'huella_015', 'foto_015.jpg'),
(16, 16, 'Medio', false, '2025-01-01', 'Exportaciones', 'J401000164', '2030-01-01', 'huella_016', 'foto_016.jpg'),
(17, 17, 'Bajo', false, '2025-01-01', 'Servicios TI', 'J401000175', '2030-01-01', 'huella_017', 'foto_017.jpg'),
(18, 18, 'Medio', false, '2025-01-01', 'Actividad agricola', 'J401000186', '2030-01-01', 'huella_018', 'foto_018.jpg'),
(19, 19, 'Medio', false, '2025-01-01', 'Venta de equipos medicos', 'J401000197', '2030-01-01', 'huella_019', 'foto_019.jpg'),
(20, 20, 'Bajo', false, '2025-01-01', 'Presupuesto Nacional', 'G401000208', '2030-01-01', 'huella_020', 'foto_020.jpg'),
(98, 998, 'Bajo', false, '2023-12-01', 'Ahorros', '99888777', '2030-01-01', 'huella_021', 'foto_021.jpg'),
(99, 999, 'Bajo', false, '2023-12-01', 'Ahorros', '99888778', '2030-01-01', 'huella_022', 'foto_022.jpg')
ON CONFLICT DO NOTHING;

INSERT INTO "EMAIL" (direccion_email, id_cliente, verificado, es_principal) VALUES
('mruiz_oficial@gmail.com', 1, true, true),
('cfernandez_design@hotmail.com', 2, true, true),
('jmedina_contador@yahoo.com', 3, true, true),
('agomez_abogada@outlook.com', 4, true, true),
('gerencia@alfaconsulting.com', 13, true, true),
('ventas@novaimport.com', 14, true, true),
('admin@orionlogistica.com', 15, true, true),
('inactivo1@demo.com', 998, true, true),
('inactivo2@demo.com', 999, true, true),
('lortega@empresa.com', 5, true, true),
('dperez_medico@gmail.com', 6, true, true),
('sramirez_admin@yahoo.com', 7, true, true),
('fgarcia_dev@outlook.com', 8, true, true),
('npineda_doc@gmail.com', 9, true, true),
('npineda_alterno@gmail.com', 9, true, true),
('rlopez_oficial@gmail.com', 10, true, true)
ON CONFLICT DO NOTHING;

INSERT INTO "TELEFONO" (numero, id_cliente, fecha_verificacion, verificado, tipo, es_principal) VALUES
('04141234561', 1, CURRENT_TIMESTAMP, true, 'Movil', true),
('04241234562', 2, CURRENT_TIMESTAMP, true, 'Movil', true),
('04121234563', 3, CURRENT_TIMESTAMP, true, 'Movil', true),
('04161234564', 4, CURRENT_TIMESTAMP, true, 'Movil', true),
('02121234513', 13, CURRENT_TIMESTAMP, true, 'Fijo', true),
('02411234514', 14, CURRENT_TIMESTAMP, true, 'Fijo', true),
('04149989988', 998, CURRENT_TIMESTAMP, true, 'Movil', true),
('04149999999', 999, CURRENT_TIMESTAMP, true, 'Movil', true),
('04121234565', 5, CURRENT_TIMESTAMP, true, 'Movil', true),
('04141234566', 6, CURRENT_TIMESTAMP, true, 'Movil', true),
('04241234567', 7, CURRENT_TIMESTAMP, true, 'Movil', true),
('04161234568', 8, CURRENT_TIMESTAMP, true, 'Movil', true),
('02129998877', 15, CURRENT_TIMESTAMP, true, 'Fijo', true),
('04149998877', 9, CURRENT_TIMESTAMP, true, 'Movil', true),
('04121010202', 10, CURRENT_TIMESTAMP, true, 'Movil', true)
ON CONFLICT DO NOTHING;

INSERT INTO "CUENTA" (
    nro_cuenta, id_cliente, id_canal_apertura, tipo_cuenta, fecha_apertura,
    saldo, moneda, estado
) VALUES
('01010000000000000001', 1, 1, 'Ahorro', '2020-01-16 10:00:00', 1500.00, 'VES', 'activa'),
('01010000000000000021', 1, 1, 'Corriente', '2021-05-10 10:00:00', 10500.00, 'VES', 'activa'),
('01010000000000000031', 1, 1, 'Ahorro', '2023-01-10 10:00:00', 3000.00, 'VES', 'activa'),
('01010000000000000002', 2, 6, 'Ahorro', '2020-06-21 14:30:00', 2300.00, 'VES', 'activa'),
('01010000000000000022', 2, 6, 'Corriente', '2022-08-15 14:30:00', 8000.00, 'VES', 'activa'),
('01010000000000000003', 3, 18, 'Corriente', '2021-03-11 09:15:00', 5200.00, 'VES', 'activa'),
('01010000000000000004', 4, 6, 'Ahorro', '2021-09-06 16:45:00', 3100.00, 'VES', 'activa'),
('01010000000000000005', 5, 1, 'Corriente', '2022-02-15 11:20:00', 6400.00, 'VES', 'activa'),
('01010000000000000006', 6, 6, 'Ahorro', '2022-07-23 08:10:00', 1800.00, 'VES', 'activa'),
('01010000000000000007', 7, 1, 'Ahorro', '2023-04-12 15:55:00', 2750.00, 'VES', 'activa'),
('01010000000000000008', 8, 6, 'Corriente', '2023-11-30 14:00:00', 7100.00, 'VES', 'activa'),
('01010000000000000009', 9, 1, 'Ahorro', '2024-05-19 10:25:00', 1950.00, 'VES', 'activa'),
('01010000000000000010', 10, 6, 'Corriente', '2024-12-02 09:00:00', 8400.00, 'VES', 'activa'),
('01010000000000000011', 11, 1, 'Ahorro', '2025-01-11 08:30:00', 2650.00, 'VES', 'activa'),
('01010000000000000012', 12, 6, 'Corriente', '2025-03-01 16:00:00', 9200.00, 'VES', 'activa'),
('01010000000000000013', 13, 2, 'Corriente', '2020-08-09 08:00:00', 25000.00, 'VES', 'activa'),
('01010000000000000023', 13, 2, 'Ahorro', '2021-10-10 08:00:00', 50000.00, 'VES', 'activa'),
('01010000000000000033', 13, 2, 'Corriente', '2023-05-05 08:00:00', 75000.00, 'VES', 'activa'),
('01010000000000000014', 14, 2, 'Corriente', '2021-11-12 14:00:00', 31500.00, 'VES', 'activa'),
('01010000000000000024', 14, 2, 'Corriente', '2022-12-01 14:00:00', 15000.00, 'VES', 'activa'),
('01010000000000000015', 15, 2, 'Corriente', '2022-05-06 16:30:00', 27800.00, 'VES', 'activa'),
('01010000000000000016', 16, 2, 'Corriente', '2023-09-10 10:15:00', 33400.00, 'VES', 'activa'),
('01010000000000000017', 17, 5, 'Corriente', '2024-02-03 11:45:00', 28900.00, 'VES', 'activa'),
('01010000000000000018', 18, 2, 'Corriente', '2024-08-16 09:30:00', 22600.00, 'VES', 'activa'),
('01010000000000000019', 19, 2, 'Corriente', '2025-03-02 10:00:00', 30100.00, 'VES', 'activa'),
('01010000000000000020', 20, 2, 'Corriente', '2025-04-11 11:00:00', 19800.00, 'VES', 'activa'),
('01010000000000000041', 21, 1, 'Ahorro', '2023-12-02 10:00:00', 23000.00, 'VES', 'activa'),
('0000-TEST-0000-0998', 998, 1, 'Ahorro', '2023-12-02 10:00:00', 100.00, 'VES', 'activa'),
('0000-TEST-0000-0999', 999, 1, 'Ahorro', '2023-12-02 10:00:00', 100.00, 'VES', 'activa')
ON CONFLICT DO NOTHING;

INSERT INTO "CUENTA_AHORRO" (nro_cuenta, limite_diario, tasa_interes) VALUES
('01010000000000000001', 2000.00, 2.50),
('01010000000000000031', 2000.00, 2.50),
('01010000000000000002', 2500.00, 2.50),
('01010000000000000004', 3000.00, 2.50),
('01010000000000000006', 2500.00, 2.50),
('01010000000000000007', 2500.00, 2.50),
('01010000000000000009', 2200.00, 2.50),
('01010000000000000011', 2400.00, 2.50),
('01010000000000000023', 20000.00, 2.50),
('01010000000000000041', 1000.00, 1.00),
('0000-TEST-0000-0998', 1000.00, 1.00),
('0000-TEST-0000-0999', 1000.00, 1.00)
ON CONFLICT DO NOTHING;

INSERT INTO "CUENTA_CORRIENTE" (nro_cuenta, limite_diario) VALUES
('01010000000000000021', 5000.00),
('01010000000000000022', 4000.00),
('01010000000000000003', 5000.00),
('01010000000000000005', 6000.00),
('01010000000000000008', 7000.00),
('01010000000000000010', 8000.00),
('01010000000000000012', 8500.00),
('01010000000000000013', 15000.00),
('01010000000000000033', 25000.00),
('01010000000000000014', 18000.00),
('01010000000000000024', 10000.00),
('01010000000000000015', 17000.00),
('01010000000000000016', 20000.00),
('01010000000000000017', 16000.00),
('01010000000000000018', 14000.00),
('01010000000000000019', 17500.00),
('01010000000000000020', 13000.00)
ON CONFLICT DO NOTHING;

INSERT INTO "DOMICILIACION_CUENTA" (nro_cuenta, nombre_servicio, monto_max_debito) VALUES
('01010000000000000021', 'Corpoelec', 100.00),
('01010000000000000021', 'CANTV', 50.00),
('01010000000000000022', 'SimpleTV', 150.00),
('01010000000000000013', 'Pago Proveedores Fijos', 5000.00),
('01010000000000000014', 'Impuestos Municipales', 2000.00),
('01010000000000000003', 'Inter', 30.00),
('01010000000000000004', 'Movistar', 20.00),
('01010000000000000005', 'Digitel', 15.00),
('01010000000000000006', 'Colegio San Jose', 150.00),
('01010000000000000015', 'Seniat', 500.00)
ON CONFLICT DO NOTHING;

INSERT INTO "AFILIACION_CANAL" (id_cliente, tipo_canal, estado_acceso) VALUES
(1, 'Digital', 'activo'),
(2, 'Digital', 'activo'),
(3, 'Electronico', 'activo'),
(13, 'Digital', 'activo'),
(14, 'Electronico', 'activo'),
(4, 'Digital', 'activo'),
(5, 'Digital', 'activo'),
(6, 'Electronico', 'activo'),
(7, 'Electronico', 'activo'),
(8, 'Digital', 'activo'),
(15, 'Digital', 'activo'),
(9, 'Digital', 'activo'),
(10, 'Electronico', 'activo')
ON CONFLICT DO NOTHING;

INSERT INTO "CONTRATO" (id_cliente, nro_cuenta, firma_digital, tyc) VALUES
(1, '01010000000000000001', 'hash_firma_1', 'Aceptado Terminos V1.0'),
(1, '01010000000000000021', 'hash_firma_1b', 'Aceptado Terminos V1.0'),
(2, '01010000000000000002', 'hash_firma_2', 'Aceptado Terminos V1.0'),
(13, '01010000000000000013', 'hash_firma_13', 'Aceptado Corp V2.0'),
(14, '01010000000000000014', 'hash_firma_14', 'Aceptado Corp V2.0'),
(3, '01010000000000000003', 'hash_firma_3', 'Aceptado Terminos V1.0'),
(4, '01010000000000000004', 'hash_firma_4', 'Aceptado Terminos V1.0'),
(5, '01010000000000000005', 'hash_firma_5', 'Aceptado Terminos V1.0'),
(15, '01010000000000000015', 'hash_firma_15', 'Aceptado Corp V2.0'),
(6, '01010000000000000006', 'hash_firma_6', 'Aceptado Terminos V1.0'),
(7, '01010000000000000007', 'hash_firma_7', 'Aceptado Terminos V1.0'),
(8, '01010000000000000008', 'hash_firma_8', 'Aceptado Terminos V1.0')
ON CONFLICT DO NOTHING;

INSERT INTO "AFILIACION_PAGOMOVIL" (numero_telefono, nro_cuenta) VALUES
('04141234561', '01010000000000000001'),
('04241234562', '01010000000000000002'),
('04121234563', '01010000000000000003'),
('04161234564', '01010000000000000004'),
('04149989988', '0000-TEST-0000-0998'),
('04149999999', '0000-TEST-0000-0999'),
('04121234565', '01010000000000000005'),
('04141234566', '01010000000000000006'),
('04241234567', '01010000000000000007'),
('04161234568', '01010000000000000008')
ON CONFLICT DO NOTHING;

INSERT INTO "TARJETA" (nro_tarjeta, nro_cuenta, id_canal_emisor, tipo_tarjeta, id_marca, motivo_emision, formato_tarjeta, clave_tarjeta, fecha_expiracion, cvv, estado) VALUES
('4012340000000001', '01010000000000000001', 19, 'Debito', 1, 'Emision', 'Fisica', 'pin', '2030-01-01', '101', 'activa'),
('5123450000000021', '01010000000000000021', 3, 'Credito', 2, 'Emision', 'Fisica', 'pin', '2030-01-01', '221', 'activa'),
('4012340000000031', '01010000000000000031', 19, 'Debito', 1, 'Emision', 'Virtual', 'pin', '2030-01-01', '331', 'activa'),
('4012340000000002', '01010000000000000002', 19, 'Debito', 1, 'Emision', 'Fisica', 'pin', '2030-01-01', '102', 'activa'),
('4012340000000022', '01010000000000000022', 19, 'Debito', 1, 'Emision', 'Fisica', 'pin', '2030-01-01', '222', 'activa'),
('6398760000000013', '01010000000000000013', 19, 'Debito', 3, 'Emision', 'Fisica', 'pin', '2030-01-01', '113', 'activa'),
('5123450000000023', '01010000000000000023', 19, 'Credito', 2, 'Emision', 'Fisica', 'pin', '2030-01-01', '223', 'activa'),
('5123450000000033', '01010000000000000033', 19, 'Credito', 2, 'Emision', 'Virtual', 'pin', '2030-01-01', '333', 'activa'),
('6398760000000014', '01010000000000000014', 19, 'Debito', 3, 'Emision', 'Fisica', 'pin', '2030-01-01', '114', 'activa'),
('5123450000000024', '01010000000000000024', 19, 'Credito', 2, 'Emision', 'Fisica', 'pin', '2030-01-01', '224', 'activa'),
('5123450000000003', '01010000000000000003', 19, 'Credito', 2, 'Emision', 'Fisica', 'pin', '2030-01-01', '103', 'activa'),
('4012340000000004', '01010000000000000004', 19, 'Debito', 1, 'Emision', 'Fisica', 'pin', '2030-01-01', '104', 'activa'),
('5123450000000005', '01010000000000000005', 19, 'Credito', 2, 'Emision', 'Fisica', 'pin', '2030-01-01', '105', 'activa'),
('4012340000000006', '01010000000000000006', 19, 'Debito', 1, 'Emision', 'Virtual', 'pin', '2030-01-01', '106', 'activa'),
('4012340000000007', '01010000000000000007', 19, 'Debito', 1, 'Emision', 'Fisica', 'pin', '2030-01-01', '107', 'activa'),
('5123450000000008', '01010000000000000008', 20, 'Credito', 2, 'Emision', 'Fisica', 'pin', '2030-01-01', '108', 'activa'),
('4012340000000009', '01010000000000000009', 19, 'Debito', 1, 'Emision', 'Fisica', 'pin', '2030-01-01', '109', 'activa'),
('5123450000000010', '01010000000000000010', 19, 'Credito', 2, 'Emision', 'Fisica', 'pin', '2030-01-01', '110', 'activa'),
('4012340000000011', '01010000000000000011', 19, 'Debito', 1, 'Emision', 'Virtual', 'pin', '2030-01-01', '111', 'activa'),
('5123450000000012', '01010000000000000012', 19, 'Credito', 4, 'Emision', 'Fisica', 'pin', '2030-01-01', '112', 'activa'),
('6398760000000015', '01010000000000000015', 19, 'Debito', 3, 'Emision', 'Fisica', 'pin', '2030-01-01', '115', 'activa'),
('6398760000000016', '01010000000000000016', 19, 'Debito', 5, 'Emision', 'Fisica', 'pin', '2030-01-01', '116', 'activa'),
('6398760000000017', '01010000000000000017', 19, 'Debito', 3, 'Emision', 'Virtual', 'pin', '2030-01-01', '117', 'activa'),
('6398760000000018', '01010000000000000018', 19, 'Debito', 3, 'Emision', 'Fisica', 'pin', '2030-01-01', '118', 'activa'),
('6398760000000019', '01010000000000000019', 19, 'Debito', 3, 'Emision', 'Fisica', 'pin', '2030-01-01', '119', 'activa'),
('6398760000000020', '01010000000000000020', 19, 'Debito', 3, 'Emision', 'Fisica', 'pin', '2030-01-01', '120', 'activa'),
('9999000011110998', '0000-TEST-0000-0998', 1, 'Debito', 1, 'Demo', 'Fisica', 'pin', '2030-01-01', '123', 'activa'),
('9999000011110999', '0000-TEST-0000-0999', 1, 'Debito', 1, 'Demo', 'Fisica', 'pin', '2030-01-01', '123', 'activa')
ON CONFLICT DO NOTHING;

INSERT INTO "TARJETA_CREDITO" (nro_tarjeta, fondo_asociado, saldo_consumido, limite_credito, tasa_interes, fecha_corte) VALUES
('5123450000000003', 'Fondo Propio', 0.00, 1000.00, 24.00, '2030-01-01'), ('5123450000000005', 'Fondo Propio', 0.00, 1500.00, 24.00, '2030-01-01'),
('5123450000000008', 'Fondo Propio', 0.00, 2000.00, 24.00, '2030-01-01'), ('5123450000000010', 'Fondo Propio', 0.00, 2500.00, 24.00, '2030-01-01'),
('5123450000000012', 'Fondo Propio', 0.00, 3000.00, 24.00, '2030-01-01'), ('5123450000000021', 'Fondo Propio', 0.00, 2000.00, 24.00, '2030-01-01'),
('5123450000000023', 'Fondo Corporativo', 0.00, 10000.00, 18.00, '2030-01-01'), ('5123450000000033', 'Fondo Corporativo', 0.00, 15000.00, 18.00, '2030-01-01'),
('5123450000000024', 'Fondo Corporativo', 0.00, 5000.00, 18.00, '2030-01-01')
ON CONFLICT DO NOTHING;

INSERT INTO "TARJETA_DEBITO" (nro_tarjeta, fondo_asociado) VALUES
('4012340000000001', 'Fondo Propio'), ('4012340000000031', 'Fondo Propio'), ('4012340000000002', 'Fondo Propio'),
('4012340000000022', 'Fondo Propio'), ('4012340000000004', 'Fondo Propio'), ('4012340000000006', 'Fondo Propio'),
('4012340000000007', 'Fondo Propio'), ('4012340000000009', 'Fondo Propio'), ('4012340000000011', 'Fondo Propio'),
('6398760000000013', 'Fondo Corporativo'), ('6398760000000014', 'Fondo Corporativo'), ('6398760000000015', 'Fondo Corporativo'),
('6398760000000016', 'Fondo Corporativo'), ('6398760000000017', 'Fondo Corporativo'), ('6398760000000018', 'Fondo Corporativo'),
('6398760000000019', 'Fondo Corporativo'), ('6398760000000020', 'Fondo Corporativo'),
('9999000011110998', 'Fondo Demo'), ('9999000011110999', 'Fondo Demo')
ON CONFLICT DO NOTHING;

INSERT INTO "PERMISOS_TARJETA" (nro_tarjeta, permiso_ecommerce, permiso_internacional) VALUES
('4012340000000001', true, false),
('5123450000000021', true, true),
('4012340000000031', true, false),
('4012340000000002', true, false),
('4012340000000022', true, false),
('5123450000000023', true, true),
('5123450000000003', true, false),
('5123450000000005', true, true),
('5123450000000008', false, true),
('5123450000000010', true, true),
('5123450000000012', true, true)
ON CONFLICT DO NOTHING;

INSERT INTO "MOVIMIENTO" (
    nro_referencia, id_tipo_mov, id_canal, id_banco_origen, id_banco_destino,
    nro_cuenta_origen, nro_cuenta_destino, descripcion_mov,
    monto_ingreso, monto_egreso, monto_comision, estado, fecha,
    saldo_origen_previo, saldo_origen_nuevo, saldo_destino_previo, saldo_destino_nuevo, ubi_transaccion
) VALUES
('REF0001', 2, 15, 1, 1, '01010000000000000001', '01010000000000000013', 'Pago POS', 0.00, 50.00, 0.50, 'Completado', CURRENT_TIMESTAMP, 1500.00, 1449.50, 1000.00, 1050.00, 'Caracas'),
('REF0002', 2, 15, 1, 1, '01010000000000000002', '01010000000000000013', 'Pago POS', 0.00, 85.00, 0.85, 'Completado', CURRENT_TIMESTAMP, 2300.00, 2214.15, 1000.00, 1085.00, 'Caracas'),
('REF0003', 2, 15, 1, 1, '01010000000000000003', '01010000000000000013', 'Pago POS', 0.00, 85.00, 0.85, 'Completado', CURRENT_TIMESTAMP, 5200.00, 5114.15, 1000.00, 1085.00, 'Caracas'),
('REF0004', 3, 1, 1, 1, '01010000000000000004', '01010000000000000014', 'Compra Ecom', 0.00, 120.00, 1.20, 'Completado', CURRENT_TIMESTAMP, 3100.00, 2978.80, 1000.00, 1120.00, 'Web'),
('REF0005', 4, 11, 1, 1, '01010000000000000005', '01010000000000000013', 'Retiro ATM', 0.00, 100.00, 5.00, 'Completado', CURRENT_TIMESTAMP, 6400.00, 6295.00, 1000.00, 1100.00, 'Caracas'),
('REF0006', 4, 11, 1, 1, '01010000000000000006', '01010000000000000013', 'Retiro ATM', 0.00, 100.00, 5.00, 'Completado', CURRENT_TIMESTAMP, 1800.00, 1695.00, 1000.00, 1100.00, 'Caracas'),
('REF0007', 4, 11, 1, 1, '01010000000000000007', '01010000000000000014', 'Retiro ATM', 0.00, 150.00, 5.00, 'Completado', CURRENT_TIMESTAMP, 2750.00, 2595.00, 1000.00, 1150.00, 'Valencia'),
('REF0008', 2, 16, 1, 1, '01010000000000000008', '01010000000000000015', 'Pago POS', 0.00, 40.00, 0.40, 'Completado', CURRENT_TIMESTAMP, 7100.00, 7059.60, 1000.00, 1040.00, 'San Cristobal'),
('REF0009', 3, 1, 1, 1, '01010000000000000009', '01010000000000000016', 'Compra Ecom', 0.00, 260.00, 2.60, 'Completado', CURRENT_TIMESTAMP, 1950.00, 1687.40, 1000.00, 1260.00, 'Web'),
('REF0010', 4, 12, 1, 1, '01010000000000000010', '01010000000000000014', 'Retiro ATM', 0.00, 150.00, 5.00, 'Completado', CURRENT_TIMESTAMP, 8400.00, 8245.00, 1000.00, 1150.00, 'Valencia'),
('REF0011', 4, 12, 1, 1, '01010000000000000011', '01010000000000000014', 'Retiro ATM', 0.00, 150.00, 5.00, 'Completado', CURRENT_TIMESTAMP, 2650.00, 2495.00, 1000.00, 1150.00, 'Valencia'),
('REF0012', 4, 12, 1, 1, '01010000000000000012', '01010000000000000014', 'Retiro ATM', 0.00, 150.00, 5.00, 'Completado', CURRENT_TIMESTAMP, 9200.00, 9045.00, 1000.00, 1150.00, 'Valencia'),
('REF0013', 2, 16, 1, 1, '01010000000000000013', '01010000000000000020', 'Pago POS', 0.00, 450.00, 4.50, 'Completado', CURRENT_TIMESTAMP, 25000.00, 24545.50, 1000.00, 1450.00, 'Valencia'),
('REF0014', 3, 2, 1, 1, '01010000000000000014', '01010000000000000019', 'Compra Ecom', 0.00, 600.00, 6.00, 'Completado', CURRENT_TIMESTAMP, 31500.00, 30894.00, 1000.00, 1600.00, 'Web'),
('REF0015', 4, 12, 1, 1, '01010000000000000015', '01010000000000000018', 'Retiro ATM', 0.00, 200.00, 5.00, 'Completado', CURRENT_TIMESTAMP, 27800.00, 27595.00, 1000.00, 1200.00, 'Maracaibo'),
('REF0016', 4, 12, 1, 1, '01010000000000000016', '01010000000000000018', 'Retiro ATM', 0.00, 200.00, 5.00, 'Completado', CURRENT_TIMESTAMP, 33400.00, 33195.00, 1000.00, 1200.00, 'Maracaibo'),
('REF0017', 2, 15, 1, 1, '01010000000000000017', '01010000000000000013', 'Pago POS', 0.00, 55.00, 0.55, 'Completado', CURRENT_TIMESTAMP, 28900.00, 28844.45, 1000.00, 1055.00, 'Caracas'),
('REF0018', 2, 15, 1, 1, '01010000000000000018', '01010000000000000013', 'Pago POS', 0.00, 65.00, 0.65, 'Completado', CURRENT_TIMESTAMP, 22600.00, 22534.35, 1000.00, 1065.00, 'Caracas'),
('REF0019', 2, 15, 1, 1, '01010000000000000019', '01010000000000000013', 'Pago POS', 0.00, 500.00, 5.00, 'Completado', CURRENT_TIMESTAMP, 30100.00, 29595.00, 1000.00, 1500.00, 'Puerto Ordaz'),
('REF0020', 2, 15, 1, 1, '01010000000000000020', '01010000000000000013', 'Pago POS', 0.00, 500.00, 5.00, 'Completado', CURRENT_TIMESTAMP, 19800.00, 19295.00, 1000.00, 1500.00, 'Puerto Ordaz'),
('REF0021', 3, 1, 1, 1, '01010000000000000021', '01010000000000000014', 'Compra Ecom', 0.00, 35.00, 0.35, 'Completado', CURRENT_TIMESTAMP, 10500.00, 10464.65, 1000.00, 1035.00, 'Web'),
('REF0022', 2, 15, 1, 1, '01010000000000000022', '01010000000000000013', 'Pago POS', 0.00, 15.00, 0.15, 'Completado', CURRENT_TIMESTAMP, 8000.00, 7984.85, 1000.00, 1015.00, 'Caracas'),
('REF0023', 2, 15, 1, 1, '01010000000000000023', '01010000000000000013', 'Pago POS', 0.00, 25.00, 0.25, 'Completado', CURRENT_TIMESTAMP, 50000.00, 49974.75, 1000.00, 1025.00, 'Caracas'),
('REF0025', 5, 10, 1, 4, '01010000000000000021', '04040000000000000456', 'Pago Movil Comercio', 0.00, 350.00, 1.50, 'Completado', CURRENT_TIMESTAMP, 10465.00, 10113.50, 1000.00, 1350.00, 'App Movil'),
('REF0026', 6, 1, 2, 1, '01050000000000000123', '01010000000000000001', 'Transf. Recibida Mercantil', 100.00, 0.00, 0.00, 'Completado', CURRENT_TIMESTAMP, 1450.00, 1550.00, 1100.00, 1000.00, 'Web'),
('REF0027', 6, 1, 3, 1, '01340000000000000456', '01010000000000000002', 'Transf. Recibida Banesco', 50.00, 0.00, 0.00, 'Completado', CURRENT_TIMESTAMP, 2215.00, 2265.00, 1050.00, 1000.00, 'Web'),
('REF0028', 6, 6, 1, 4, '01010000000000000013', '01080000000000000789', 'Transf. a Provincial', 0.00, 5000.00, 15.00, 'Completado', CURRENT_TIMESTAMP, 24550.00, 19535.00, 1000.00, 6000.00, 'App Movil'),
('REF0029', 5, 10, 1, 2, '01010000000000000001', '01050000000000000999', 'Pago Movil Almuerzo', 0.00, 15.00, 0.15, 'Completado', CURRENT_TIMESTAMP, 1350.00, 1334.85, 1000.00, 1015.00, 'App Movil'),
('REF0030', 5, 10, 1, 3, '01010000000000000002', '01340000000000000888', 'Pago Movil Deuda', 0.00, 30.00, 0.30, 'Completado', CURRENT_TIMESTAMP, 2165.00, 2134.70, 1000.00, 1030.00, 'App Movil'),
('REF0031', 5, 10, 4, 1, '01080000000000000777', '01010000000000000003', 'Pago Movil Recibido Regalo', 25.00, 0.00, 0.00, 'Completado', CURRENT_TIMESTAMP, 5115.00, 5140.00, 1025.00, 1000.00, 'App Movil'),
('REF0032', 3, 1, 1, 1, '01010000000000000003', '01010000000000000014', 'Compra Amazon', 0.00, 45.00, 0.45, 'Completado', CURRENT_TIMESTAMP, 5115.00, 5069.55, 1000.00, 1045.00, 'Web'),
('REF0033', 3, 1, 1, 1, '01010000000000000004', '01010000000000000014', 'Suscripcion Netflix', 0.00, 10.00, 0.10, 'Completado', CURRENT_TIMESTAMP, 2980.00, 2969.90, 1000.00, 1010.00, 'Web'),
('REF0034', 6, 1, 5, 1, '01140000000000000555', '01010000000000000005', 'Transf. Recibida Bancaribe', 200.00, 0.00, 0.00, 'Completado', CURRENT_TIMESTAMP, 6300.00, 6500.00, 1200.00, 1000.00, 'Web'),
('REF0035', 6, 6, 6, 1, '01510000000000000666', '01010000000000000006', 'Transf. Recibida BFC', 150.00, 0.00, 0.00, 'Completado', CURRENT_TIMESTAMP, 1700.00, 1850.00, 1150.00, 1000.00, 'App Movil'),
('REF0036', 5, 10, 1, 7, '01010000000000000007', '01160000000000000777', 'Pago Movil Farmacia', 0.00, 25.00, 0.25, 'Completado', CURRENT_TIMESTAMP, 2600.00, 2574.75, 1000.00, 1025.00, 'App Movil'),
('REF0037', 5, 10, 1, 8, '01010000000000000008', '01050000000000000888', 'Pago Movil Panaderia', 0.00, 10.00, 0.10, 'Completado', CURRENT_TIMESTAMP, 7060.00, 7049.90, 1000.00, 1010.00, 'App Movil'),
('REF0038', 6, 1, 3, 1, '01340000000000000888', '01010000000000000008', 'Transf. Recibida Capital Uno', 300.00, 0.00, 0.00, 'Completado', CURRENT_TIMESTAMP, 7100.00, 7400.00, 1300.00, 1000.00, 'Web'),
('REF0039', 6, 6, 4, 1, '01080000000000000999', '01010000000000000009', 'Transf. Recibida Horizonte', 150.00, 0.00, 0.00, 'Completado', CURRENT_TIMESTAMP, 1950.00, 2100.00, 1150.00, 1000.00, 'App Movil'),
('REF0040', 5, 10, 1, 5, '01010000000000000010', '01050000000000001010', 'Pago Movil Medico', 0.00, 45.00, 0.45, 'Completado', CURRENT_TIMESTAMP, 8400.00, 8354.55, 1000.00, 1045.00, 'App Movil'),
('REF0041', 5, 10, 6, 1, '01340000000000001111', '01010000000000000011', 'Pago Movil Recibido Colegio', 60.00, 0.00, 0.00, 'Completado', CURRENT_TIMESTAMP, 2650.00, 2710.00, 1060.00, 1000.00, 'App Movil'),

('REF1002', 3, 1, 1, 1, '01010000000000000002', '01010000000000000014', 'Compra ecommerce reversada', 0.00, 120.00, 1.20, 'Reversado', '2023-03-02 20:30:00', 2300.00, 2300.00, 31500.00, 31500.00, 'Web'),
('REF1003', 4, 11, 1, 1, '01010000000000000003', '01010000000000000013', 'Retiro ATM no dispensado', 0.00, 200.00, 5.00, 'Fallido', '2023-05-20 14:25:00', 5200.00, 5200.00, 25000.00, 25000.00, 'Caracas'),
('REF1005', 6, 6, 1, 3, '01010000000000000013', '01010000000000000008', 'Transferencia interbancaria en cola', 300.00, 300.00, 1.50, 'Pendiente', '2023-10-02 18:11:00', 26000.00, 26000.00, 7100.00, 7100.00, 'App Movil'),
('REF1007', 2, 16, 1, 1, '01010000000000000007', '01010000000000000015', 'Pago POS reversado por reclamo', 0.00, 90.00, 0.90, 'Reversado', '2024-01-15 16:40:00', 2750.00, 2750.00, 27800.00, 27800.00, 'Valencia'),
('REF1010', 5, 10, 1, 1, '01010000000000000012', '01010000000000000020', 'Pago Movil sin confirmacion', 0.00, 80.00, 0.80, 'Fallido', '2024-06-09 11:42:00', 9200.00, 9200.00, 19800.00, 19800.00, 'App Movil'),
('REF1012', 2, 15, 1, 1, '01010000000000000002', '01010000000000000013', 'Pago POS pendiente lote', 0.00, 35.00, 0.35, 'Pendiente', '2024-10-05 18:07:00', 2300.00, 2300.00, 25078.00, 25078.00, 'Caracas'),
('REF1014', 4, 13, 1, 1, '01010000000000000005', '01010000000000000013', 'Retiro ATM anulado', 0.00, 300.00, 5.00, 'Reversado', '2025-03-29 19:22:00', 6400.00, 6400.00, 25078.00, 25078.00, 'Maracaibo'),
('REF1017', 2, 17, 1, 1, '01010000000000000009', '01010000000000000016', 'Pago POS rechazado', 0.00, 70.00, 0.70, 'Fallido', '2025-11-20 12:12:00', 1950.00, 1950.00, 33400.00, 33400.00, 'Maracaibo'),
('REF1018', 3, 1, 1, 1, '01010000000000000010', '01010000000000000017', 'Compra ecommerce reversada por fraude', 0.00, 180.00, 1.80, 'Reversado', '2026-02-12 23:02:00', 8400.00, 8400.00, 28900.00, 28900.00, 'Web'),
('REF1020', 5, 10, 1, 1, '01010000000000000001', '01010000000000000002', 'Pago Movil pendiente autorizacion', 0.00, 25.00, 0.25, 'Pendiente', '2026-04-01 08:09:00', 1466.22, 1466.22, 2300.00, 2300.00, 'App Movil'),
('REF1021', 2, 15, 1, 1, '01010000000000000009', '01010000000000000013', 'Pago POS en revision', 0.00, 42.00, 0.42, 'Pendiente', '2026-04-02 10:20:00', 1950.00, 1950.00, 25078.00, 25078.00, 'Caracas'),
('REF1022', 3, 1, 1, 1, '01010000000000000011', '01010000000000000014', 'Compra ecommerce rechazada', 0.00, 75.00, 0.75, 'Fallido', '2026-04-03 14:05:00', 2650.00, 2650.00, 31675.00, 31675.00, 'Web'),
('REF1023', 4, 11, 1, 1, '01010000000000000012', '01010000000000000013', 'Retiro ATM reversado por reclamo', 0.00, 110.00, 5.00, 'Reversado', '2026-04-04 18:45:00', 9200.00, 9200.00, 25078.00, 25078.00, 'Puerto La Cruz')
ON CONFLICT DO NOTHING;

INSERT INTO "MOVIMIENTO_PAGO_POS" (nro_referencia, nro_tarjeta) VALUES
('REF0001', '4012340000000001'), ('REF0002', '4012340000000002'), ('REF0003', '5123450000000003'),
('REF0008', '5123450000000008'), ('REF0013', '6398760000000013'), ('REF0017', '6398760000000017'),
('REF0018', '6398760000000018'), ('REF0019', '6398760000000019'), ('REF0020', '6398760000000020'),
('REF0022', '4012340000000022'), ('REF0023', '5123450000000023'),
('REF1007', '4012340000000007'), ('REF1012', '4012340000000002'),
('REF1017', '4012340000000009'),
('REF1021', '4012340000000009')
ON CONFLICT DO NOTHING;

INSERT INTO "MOVIMIENTO_PAGO_ECOMMERCE" (nro_referencia, nro_tarjeta, pagina_web) VALUES
('REF0004', '4012340000000004', 'www.repuestos24.com'),
('REF0009', '4012340000000009', 'www.insumospro.com'),
('REF0014', '6398760000000014', 'www.logisticashop.com'),
('REF0021', '5123450000000021', 'www.streamplus.com'),
('REF0032', '5123450000000003', 'www.amazon.com'),
('REF0033', '4012340000000004', 'www.netflix.com'),
('REF1002', '4012340000000002', 'www.marketglobal.com'),
('REF1018', '5123450000000010', 'www.electroshop.com'),
('REF1022', '4012340000000011', 'www.comprasflash.com')
ON CONFLICT DO NOTHING;

INSERT INTO "MOVIMIENTO_RETIRO_ATM" (nro_referencia, nro_tarjeta) VALUES
('REF0005', '5123450000000005'), ('REF0006', '4012340000000006'), ('REF0007', '4012340000000007'),
('REF0010', '5123450000000010'), ('REF0011', '4012340000000011'), ('REF0012', '5123450000000012'),
('REF0015', '6398760000000015'), ('REF0016', '6398760000000016'),
('REF1003', '5123450000000003'), ('REF1014', '5123450000000005'),
('REF1023', '5123450000000012')
ON CONFLICT DO NOTHING;

INSERT INTO "MOVIMIENTO_TRANSFERENCIA" (nro_referencia, medio) VALUES
('REF0026', 'Portal Web'),
('REF0027', 'Portal Web'),
('REF0028', 'App Movil'),
('REF0034', 'Portal Web'),
('REF0035', 'App Movil'),
('REF0038', 'Portal Web'),
('REF0039', 'App Movil'),
('REF1005', 'App Movil')
ON CONFLICT DO NOTHING;

INSERT INTO "MOVIMIENTO_PAGOMOVIL" (nro_referencia, pm_telefono, pm_ci) VALUES
('REF0025', '04141234567', 'V20123456'),
('REF0029', '04141112233', 'V12345678'),
('REF0030', '04249998877', 'V87654321'),
('REF0031', '04125554433', 'V11223344'),
('REF0036', '04147778899', 'V22334455'),
('REF0037', '04248889900', 'V33445566'),
('REF0040', '04145556677', 'V10203040'),
('REF0041', '04249991122', 'V11223344'),
('REF1010', '04143334455', 'V25836914'),
('REF1020', '04145556688', 'V95175384')
ON CONFLICT DO NOTHING;
