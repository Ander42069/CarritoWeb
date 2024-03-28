CREATE DATABASE tienda;

drop database tienda;

USE tienda;


-- TABLAS BASE DE DATOS tienda


-- Tabla para almacenar los usuarios
CREATE TABLE usuarios (
	id INT AUTO_INCREMENT PRIMARY KEY,
	nombre VARCHAR(100),
	apellido VARCHAR(50),
    email VARCHAR(100),
    contraseña VARCHAR(100)
);

-- Tabla para almacenar los productos de la tienda
CREATE TABLE productos (
	id INT AUTO_INCREMENT PRIMARY KEY,
	nombre VARCHAR(100),
	descripcion TEXT,
	precio DECIMAL(10, 2),
	stock INT
);

-- Tabla para almacenar los productos del carrito
/* CREATE TABLE carrito (
	id INT AUTO_INCREMENT PRIMARY KEY,
	usuario_id INT,
	producto_id INT,
	cantidad INT,
	FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
	FOREIGN KEY (producto_id) REFERENCES productos(id)
);*/

CREATE TABLE carrito (
	id INT AUTO_INCREMENT PRIMARY KEY,
	nombre VARCHAR(100),
    precio DECIMAL(10, 2),
    elemento_id INT
);

select * from carrito;

-- Tabla para almacenar el pago del usuario
CREATE TABLE pagos (
	id INT AUTO_INCREMENT PRIMARY KEY,
	usuario_id INT,
	monto DECIMAL(10, 2),
	fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

-- Tabla para almacenar las órdenes de compra
CREATE TABLE ordenes (
	  id INT AUTO_INCREMENT PRIMARY KEY,
	  fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	  producto_id INT,
	  cantidad INT,
	  total DECIMAL(10, 2),
	  FOREIGN KEY (producto_id) REFERENCES productos(id)
);


-- BITACORA DE TABLAS


-- Tabla para almacenar bitacora de la tabla carrito
CREATE TABLE bitacora_carrito (
  id INT AUTO_INCREMENT PRIMARY KEY,
  carrito_id INT,
  fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  accion VARCHAR(100),
  FOREIGN KEY (carrito_id) REFERENCES carrito(id)
);

-- Tabla para almacenar bitacora de la tabla pagos
CREATE TABLE bitacora_pagos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  pago_id INT,
  fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  accion VARCHAR(100),
  FOREIGN KEY (pago_id) REFERENCES pagos(id)
);

-- Tabla para almacenar bitacora de la tabla ordenes
CREATE TABLE bitacora_ordenes (
	id INT AUTO_INCREMENT PRIMARY KEY,
	orden_id INT,
	fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	accion VARCHAR(100),
	FOREIGN KEY (orden_id) REFERENCES ordenes(id)
);

CREATE TABLE bitacora_productos (
	id INT AUTO_INCREMENT PRIMARY KEY,
	producto_id INT,
	fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	accion VARCHAR(100),
	descripcion TEXT,
	precio DECIMAL(10, 2),
	stock INT,
	FOREIGN KEY (producto_id) REFERENCES productos(id)
);


-- PROCEDIMIENTOS ALMACENADOS


-- Procedimiento para agregar un producto a la base de datos
DELIMITER $$
CREATE PROCEDURE agregar_producto(
	IN nombre_producto VARCHAR(100),
	IN descripcion_producto TEXT,
	IN precio_producto DECIMAL(10, 2),
	IN stock_producto INT
)
BEGIN
	INSERT INTO productos (nombre, descripcion, precio, stock)
	VALUES (nombre_producto, descripcion_producto, precio_producto, stock_producto);
	  
	INSERT INTO bitacora_productos (accion)
	VALUES (CONCAT('Se agregó el producto "', nombre_producto, '" a la tienda.'));
END$$
DELIMITER ;

-- Procedimiento para realizar una orden de compra
DELIMITER $$
CREATE PROCEDURE realizar_orden(
  IN producto_id INT,
  IN cantidad_producto INT
)
BEGIN
  DECLARE producto_stock INT;
  DECLARE producto_precio DECIMAL(10, 2);
  DECLARE total_pedido DECIMAL(10, 2);
  
  SELECT stock INTO producto_stock FROM productos WHERE id = producto_id;
  SELECT precio INTO producto_precio FROM productos WHERE id = producto_id;
  
  IF producto_stock >= cantidad_producto THEN
    SET total_pedido = producto_precio * cantidad_producto;
    
    START TRANSACTION;
    
    UPDATE productos SET stock = stock - cantidad_producto WHERE id = producto_id;
    
    INSERT INTO ordenes (producto_id, cantidad, total)
    VALUES (producto_id, cantidad_producto, total_pedido);
    
    INSERT INTO bitacora_ordenes (accion)
    VALUES (CONCAT('Se realizó una orden de compra del producto con ID ', producto_id));
    
    COMMIT;
  ELSE
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock insuficiente.';
  END IF;
END$$
DELIMITER ;


-- TRIGGERS


-- Trigger para controlar el stock mínimo de productos
DELIMITER $$
CREATE TRIGGER control_stock
AFTER UPDATE ON productos
FOR EACH ROW
BEGIN
  DECLARE stock_minimo INT;
  
  SELECT stock FROM productos WHERE id = NEW.id INTO stock_minimo;
  
  IF stock_minimo <= 10 THEN
    INSERT INTO bitacora_productos (accion)
    VALUES (CONCAT('El producto con ID ', NEW.id, ' tiene stock mínimo.'));
  END IF;
END$$
DELIMITER ;


-- ADMINISTRACION DE TRANSACCIONES

-- Transaccion para insertar un nuevo producto
START TRANSACTION;

-- Inserción de un nuevo producto
INSERT INTO productos (nombre, descripcion, precio, stock)
VALUES ('Producto 1', 'Descripción del producto 1', 10.99, 100);

-- Obtener el ID del último producto insertado
SET @last_product_id = LAST_INSERT_ID();

-- Inserción de una nueva orden
INSERT INTO ordenes (producto_id, cantidad, total)
VALUES (@last_product_id, 5, 54.95);

-- Actualizar el stock del producto
UPDATE productos
SET stock = stock - 5
WHERE id = @last_product_id;

COMMIT;


DELIMITER $$
START TRANSACTION;

-- Inserción de un nuevo producto
INSERT INTO productos (nombre, descripcion, precio, stock)
VALUES ('Producto 2', 'Descripción del producto 2', 15.99, 50);

-- Obtener el ID del último producto insertado
SET @last_product_id = LAST_INSERT_ID();

-- Inserción de una nueva orden
INSERT INTO ordenes (producto_id, cantidad, total)
VALUES (@last_product_id, 10, 159.90);

-- Simulación de un error: intentar insertar una orden con un producto inexistente
INSERT INTO ordenes (producto_id, cantidad, total)
VALUES (999, 5, 99.95);

IF ROW_COUNT() = 0 THEN
    ROLLBACK;
ELSE
    -- Actualizar el stock del producto
    UPDATE productos
    SET stock = stock - 10
    WHERE id = @last_product_id;

		COMMIT;
	END IF;
END $$
DELIMITER ;


-- ADMINISTRACION DE USUARIOS


-- Creacion de usuario 'edgar' en el 'localhost' con contraseña '12345'
CREATE USER 'edgar'@'localhost' IDENTIFIED BY '12345';

-- Asignacion de permisos: 'select', 'insert' y 'update on' para la bd 'tienda_ropa' en la tabla 'usarios' para el usuario previamente creado 'edgar'
GRANT SELECT, INSERT, UPDATE ON tienda_ropa.usuarios TO 'edgar'@'localhost';

-- Revocacion de permisos: 'select', 'insert' y 'update on' para la bd 'tienda_ropa' en la tabla 'usuarios' para el usuario previamente creado 'edgar'
REVOKE SELECT, INSERT, UPDATE ON tienda_ropa.usuarios FROM 'edgar'@'localhost';

-- Eliminacion de usuario: se elimina el usuario previamente creado 'edgar'
DROP USER 	'edgar'@'localhost';




-- COMANDOS EXTRA

DROP DATABASE if exists tienda_ropa;

SELECT * FROM productos;

SELECT * FROM ordenes;

SELECT * FROM pagos;

SELECT * FROM carrito;

SELECT * FROM usuarios;

SELECT * FROM bitacora_pagos;

SELECT * FROM bitacora_ordenes;

SELECT * FROM bitacora_carrito;
