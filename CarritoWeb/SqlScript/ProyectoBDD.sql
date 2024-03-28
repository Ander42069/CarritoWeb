select * from carrito;

select * from bitacora_carrito;

drop database tienda;

drop table carrito;

drop table bitacora_carrito;

show triggers;

show procedure status;

delete from carrito where id = 1;

truncate table carrito;

truncate table bitacora_carrito;

show engines;


-- Creacion base de datos 'tienda'
CREATE DATABASE tienda;

-- Seleccionamos base de datos 'tienda'
USE tienda;



-- Creamos tabla 'carrito'
CREATE TABLE carrito (
	id INT AUTO_INCREMENT PRIMARY KEY,
	nombre VARCHAR(100),
    precio INT,
    elemento_id INT
);

-- Creamos tabla 'bitacora_carrito'
CREATE TABLE bitacora_carrito (
	id INT AUTO_INCREMENT PRIMARY KEY,
    operacion VARCHAR(20),
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    nombre_anterior VARCHAR(100),
    precio_anterior INT,
    elemento_id_anterior INT
);




-- Trigger que se activa despues de insertar un elemento en la tabla carrito, y registra su operacion y sus valores antiguos
DELIMITER //

CREATE TRIGGER carrito_after_insert
AFTER INSERT ON carrito
FOR EACH ROW
BEGIN
    INSERT INTO bitacora_carrito (operacion, nombre_anterior, precio_anterior, elemento_id_anterior)
    VALUES ('Inserción', NULL, NULL, NULL);
END //

DELIMITER ;

-- Trigger que se activa antes de eliminar un elemento en la tabla carrito, y registra su operacion y sus valores antiguos
DELIMITER //

CREATE TRIGGER carrito_before_delete
BEFORE DELETE ON carrito
FOR EACH ROW
BEGIN
    INSERT INTO bitacora_carrito (operacion, nombre_anterior, precio_anterior, elemento_id_anterior)
    VALUES ('Eliminación', OLD.nombre, OLD.precio, OLD.elemento_id);
END //

DELIMITER ;




-- Procedure que inserta un elemento en el carrito
DELIMITER //

CREATE PROCEDURE InsertarElementoEnCarrito(
    IN p_nombre VARCHAR(100),
    IN p_precio INT,
    IN p_elemento_id INT
)
BEGIN
    INSERT INTO carrito (nombre, precio, elemento_id)
    VALUES (p_nombre, p_precio, p_elemento_id);
END //

DELIMITER ;

-- Procedure que elimina un elemento del carrito
DELIMITER //

CREATE PROCEDURE EliminarElementoDeCarrito(
    IN p_elemento_id INT
)
BEGIN
    DELETE FROM carrito
    WHERE elemento_id = p_elemento_id;
END //

DELIMITER ;





-- Federacion de base de datos

CREATE USER 'root'@'%' IDENTIFIED BY '42069';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;


-- Creamos tabla 'carrito'
CREATE TABLE carrito (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100),
    precio INT,
    elemento_id INT
) ENGINE=FEDERATED CONNECTION='mysql://root:42069@192.168.1.74/tienda/carrito';

-- Creamos tabla 'bitacora_carrito'
CREATE TABLE bitacora_carrito (
    id INT AUTO_INCREMENT PRIMARY KEY,
    operacion VARCHAR(20),
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    nombre_anterior VARCHAR(100),
    precio_anterior INT,
    elemento_id_anterior INT
) ENGINE=FEDERATED CONNECTION='mysql://root:42069@192.168.1.74/tienda/bitacora_carrito';






-- Admin de usuarios

-- Creacion de un usuario 'Admin'
CREATE USER 'Admin'@'localhost' IDENTIFIED BY '12345';
GRANT ALL PRIVILEGES ON *.* TO 'Admin'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;



-- Creacion de un usuario 'insert_user' que tenga los privilegios para insertar en la tabla 'carrito' de nuestra base de datos 'tienda'
CREATE USER 'insert_user'@'localhost' IDENTIFIED BY '12345';
GRANT INSERT ON tienda.carrito TO 'insert_user'@'localhost';
GRANT SELECT ON tienda.carrito TO 'insert_user'@'localhost';
GRANT EXECUTE ON tienda.carrito TO 'insert_user'@'localhost';

-- Creacion de un usuario 'delete_user' que tenga los privilegios para eliminar en la tabla 'carrito' de nuesta base de datos 'tienda'
CREATE USER 'delete_user'@'localhost' IDENTIFIED BY '12345';
GRANT DELETE ON tienda.carrito TO 'delete_user'@'localhost';






-- Inicio de la transacción
START TRANSACTION;

-- Insertar un elemento en la tabla "carrito"
INSERT INTO carrito (nombre, precio, elemento_id)
VALUES ('Producto 1', 10, 1);

-- Obtener los valores anteriores de la tabla "carrito"
SELECT nombre, precio, elemento_id INTO @nombre_anterior, @precio_anterior, @elemento_id_anterior
FROM carrito
WHERE id = LAST_INSERT_ID();

-- Insertar una entrada en la tabla "bitacora_carrito" con los valores anteriores
INSERT INTO bitacora_carrito (operacion, nombre_anterior, precio_anterior, elemento_id_anterior)
VALUES ('Inserción', @nombre_anterior, @precio_anterior, @elemento_id_anterior);

-- Si ocurre algún error, deshacer la transacción
ROLLBACK;

-- Si no hay errores, confirmar la transacción
COMMIT;


