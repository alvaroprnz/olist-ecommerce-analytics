USE Olist;
GO

-- Crear vista analítica con datos limpios y convertidos
CREATE OR ALTER VIEW vw_ventas_consolidadas AS
SELECT 
    o.order_id,
    o.customer_id,
    c.customer_city,
    c.customer_state,
    TRY_CAST(o.order_purchase_timestamp AS DATETIME2) AS fecha_compra,
    TRY_CAST(o.order_delivered_customer_date AS DATETIME2) AS fecha_entrega_cliente,
    TRY_CAST(o.order_estimated_delivery_date AS DATETIME2) AS fecha_estimada_entrega,
    i.order_item_id,
    i.product_id,
    p.product_category_name,
    -- Ajuste de escala de precios y fletes (división entre 100)
    i.price / 100.0 AS precio,
    i.freight_value / 100.0 AS flete,
    (i.price + i.freight_value) / 100.0 AS total_orden_item
FROM olist_orders_dataset o
INNER JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
INNER JOIN olist_order_items_dataset i ON o.order_id = i.order_id
LEFT JOIN olist_products_dataset p ON i.product_id = p.product_id
WHERE o.order_status = 'delivered';
GO

SELECT 
    FORMAT(fecha_compra, 'yyyy-MM') AS mes,
    COUNT(DISTINCT order_id) AS total_pedidos,
    ROUND(SUM(precio), 2) AS ingresos_totales,
    ROUND(AVG(precio), 2) AS ticket_promedio
FROM vw_ventas_consolidadas
GROUP BY FORMAT(fecha_compra, 'yyyy-MM')
ORDER BY mes ASC;

SELECT TOP 10
    ISNULL(product_category_name, 'Sin Categoria') AS categoria,
    COUNT(DISTINCT order_id) AS total_pedidos,
    ROUND(SUM(precio), 2) AS ventas_totales,
    ROUND(AVG(precio), 2) AS precio_promedio
FROM vw_ventas_consolidadas
GROUP BY product_category_name
ORDER BY ventas_totales DESC;

USE Olist;
GO

-- 1. Métricas Globales de Logística (Pregunta 3)
SELECT 
    COUNT(DISTINCT order_id) AS total_pedidos_entregados,
    ROUND(AVG(CAST(DATEDIFF(day, fecha_compra, fecha_entrega_cliente) AS FLOAT)), 2) AS dias_promedio_entrega_real,
    ROUND(AVG(CAST(DATEDIFF(day, fecha_compra, fecha_estimada_entrega) AS FLOAT)), 2) AS dias_promedio_prometidos,
    SUM(CASE WHEN fecha_entrega_cliente > fecha_estimada_entrega THEN 1 ELSE 0 END) AS total_pedidos_retrasados,
    ROUND(SUM(CASE WHEN fecha_entrega_cliente > fecha_estimada_entrega THEN 1.0 ELSE 0.0 END) * 100.0 / COUNT(DISTINCT order_id), 2) AS porcentaje_retraso
FROM vw_ventas_consolidadas;

-- 2. Desempeño Logístico por Estado del Cliente / Región Top 10 (Pregunta 4)
SELECT TOP 10
    customer_state AS estado_cliente,
    COUNT(DISTINCT order_id) AS total_pedidos,
    ROUND(AVG(CAST(DATEDIFF(day, fecha_compra, fecha_entrega_cliente) AS FLOAT)), 2) AS dias_promedio_entrega,
    SUM(CASE WHEN fecha_entrega_cliente > fecha_estimada_entrega THEN 1 ELSE 0 END) AS pedidos_retrasados,
    ROUND(SUM(CASE WHEN fecha_entrega_cliente > fecha_estimada_entrega THEN 1.0 ELSE 0.0 END) * 100.0 / COUNT(DISTINCT order_id), 2) AS porcentaje_retraso
FROM vw_ventas_consolidadas
GROUP BY customer_state
ORDER BY total_pedidos DESC;

USE Olist;
GO

IF OBJECT_ID('olist_order_reviews_dataset', 'U') IS NULL
CREATE TABLE olist_order_reviews_dataset (
    review_id NVARCHAR(50) NULL,
    order_id NVARCHAR(50) NOT NULL,
    review_score INT NULL,
    review_comment_title NVARCHAR(200) NULL,
    review_comment_message NVARCHAR(MAX) NULL,
    review_creation_date NVARCHAR(50) NULL,
    review_answer_timestamp NVARCHAR(50) NULL
);

-- Preguta 5
USE Olist;
GO

SELECT 
    CASE 
        WHEN TRY_CAST(o.order_delivered_customer_date AS DATETIME2) > TRY_CAST(o.order_estimated_delivery_date AS DATETIME2) THEN 'Entrega Con Retraso'
        ELSE 'Entrega A Tiempo'
    END AS estado_entrega,
    COUNT(DISTINCT o.order_id) AS total_pedidos,
    ROUND(AVG(CAST(r.review_score AS FLOAT)), 2) AS puntuacion_promedio,
    ROUND(SUM(CASE WHEN CAST(r.review_score AS INT) = 1 THEN 1.0 ELSE 0.0 END) * 100.0 / COUNT(*), 2) AS pct_puntuacion_1_estrella,
    ROUND(SUM(CASE WHEN CAST(r.review_score AS INT) = 5 THEN 1.0 ELSE 0.0 END) * 100.0 / COUNT(*), 2) AS pct_puntuacion_5_estrellas
FROM olist_orders_dataset o
INNER JOIN olist_order_reviews_dataset r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY 
    CASE 
        WHEN TRY_CAST(o.order_delivered_customer_date AS DATETIME2) > TRY_CAST(o.order_estimated_delivery_date AS DATETIME2) THEN 'Entrega Con Retraso'
        ELSE 'Entrega A Tiempo'
    END;