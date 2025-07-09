-- Script de inicialización para PostgreSQL
-- Se ejecuta automáticamente al crear el contenedor

-- Crear tabla de usuarios
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Crear tabla de productos (ejemplo)
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insertar datos de ejemplo
INSERT INTO users (name, email) VALUES
    ('Juan Pérez', 'juan@email.com'),
    ('María García', 'maria@email.com'),
    ('Carlos López', 'carlos@email.com');

INSERT INTO products (name, price, description) VALUES
    ('Producto A', 29.99, 'Descripción del producto A'),
    ('Producto B', 45.50, 'Descripción del producto B'),
    ('Producto C', 12.00, 'Descripción del producto C');

-- Crear índices para performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_products_name ON products(name); 