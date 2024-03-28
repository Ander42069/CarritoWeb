CREATE DATABASE tienda_ropa;

USE tienda_ropa;

-- Tabla para almacenar los productos de la tienda
CREATE TABLE productos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100),
  descripcion TEXT,
  precio DECIMAL(10, 2),
  stock INT
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

-- Tabla para almacenar las bitácoras de acciones
CREATE TABLE bitacoras (
  id INT AUTO_INCREMENT PRIMARY KEY,
  fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  accion VARCHAR(100)
);



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
  
  INSERT INTO bitacoras (accion)
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
    
    INSERT INTO bitacoras (accion)
    VALUES (CONCAT('Se realizó una orden de compra del producto con ID ', producto_id));
    
    COMMIT;
  ELSE
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock insuficiente.';
  END IF;
END$$
DELIMITER ;

-- Trigger para controlar el stock mínimo de productos
DELIMITER $$
CREATE TRIGGER control_stock
AFTER UPDATE ON productos
FOR EACH ROW
BEGIN
  DECLARE stock_minimo INT;
  
  SELECT stock FROM productos WHERE id = NEW.id INTO stock_minimo;
  
  IF stock_minimo <= 10 THEN
    INSERT INTO bitacoras (accion)
    VALUES (CONCAT('El producto con ID ', NEW.id, ' tiene stock mínimo.'));
  END IF;
END$$
DELIMITER ;