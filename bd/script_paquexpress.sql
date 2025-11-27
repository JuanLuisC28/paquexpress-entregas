CREATE DATABASE paquexpress_db;
USE paquexpress_db;

CREATE TABLE agentes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario VARCHAR(50) NOT NULL UNIQUE,
    password_md5 VARCHAR(100) NOT NULL, 
    nombre VARCHAR(100)
);


CREATE TABLE paquetes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    agente_id INT,
    direccion_destino VARCHAR(200) NOT NULL,
    latitud_destino DOUBLE, 
    longitud_destino DOUBLE, 
    estado ENUM('pendiente', 'entregado') DEFAULT 'pendiente',
    foto_evidencia_path VARCHAR(255),
    fecha_entrega DATETIME,
    ubicacion_entrega_gps VARCHAR(100), 
    FOREIGN KEY (agente_id) REFERENCES agentes(id)
);

INSERT INTO agentes (usuario, password_md5, nombre) 
VALUES ('admin', '81dc9bdb52d04dc20036dbd8313ed055', 'Juan Perez');

INSERT INTO paquetes (agente_id, direccion_destino, latitud_destino, longitud_destino) 
VALUES 
(1, 'Av. Universidad 123, Centro', 20.5937, -100.392),
(1, 'Calle 5 de Mayo 45, La Cruz', 20.5950, -100.395);