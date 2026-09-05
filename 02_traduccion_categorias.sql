USE Olist;
GO

CREATE OR ALTER VIEW vw_ventas_consolidadas AS
SELECT 
    o.order_id,
    i.order_item_id,
    c.customer_id,
    c.customer_city,
    c.customer_state,
    -- Mapeo al español de todas las categoríasq y productos
    CASE p.product_category_name
        -- Categorías secundarias:
        WHEN 'telefonia_fixa' THEN 'Telefonía Fija'
        WHEN 'tablets_impressao_imagem' THEN 'Tablets e Impresión de Imágenes'
        WHEN 'sinalizacao_e_seguranca' THEN 'Señalización y Seguridad'
        WHEN 'seguros_e_servicos' THEN 'Seguros y Servicios'
        WHEN 'portateis_cozinha_e_preparadores_de_alimentos' THEN 'Procesadores y Portátiles de Cocina'
        WHEN 'portateis_casa_forno_e_cafe' THEN 'Electrodomésticos de Cocina y Café'
        WHEN 'moveis_sala' THEN 'Muebles de Sala'
        WHEN 'moveis_quarto' THEN 'Muebles de Dormitorio'
        WHEN 'moveis_cozinha_area_de_servico_jantar_e_jardim' THEN 'Muebles de Cocina, Jardín y Comedor'
        WHEN 'moveis_colchao_e_estofado' THEN 'Colchones y Tapicería'
        WHEN 'livros_tecnicos' THEN 'Libros Técnicos'
        WHEN 'livros_importados' THEN 'Libros Importados'
        WHEN 'la_cuisine' THEN 'Artículos de Cocina Gourmet'
        WHEN 'industria_comercio_e_negocios' THEN 'Industria, Comercio y Negocios'
        WHEN 'fashion_roupa_masculina' THEN 'Moda Masculina'
        WHEN 'fashion_roupa_infanto_juvenil' THEN 'Moda Infantil y Juvenil'
        WHEN 'fashion_roupa_feminina' THEN 'Moda Femenina'
        WHEN 'fashion_esporte' THEN 'Ropa Deportiva'
        WHEN 'eletroportateis' THEN 'Pequeños Electrodomésticos'
        WHEN 'construcao_ferramentas_seguranca' THEN 'Herramientas de Seguridad en Construcción'
        WHEN 'construcao_ferramentas_jardim' THEN 'Herramientas de Jardín y Construcción'
        WHEN 'construcao_ferramentas_ferramentas' THEN 'Herramientas Manuales y Equipos'
        WHEN 'climatizacao' THEN 'Climatización y Aire Acondicionado'
        WHEN 'cine_foto' THEN 'Cine y Fotografía'
        WHEN 'cds_dvds_musicais' THEN 'CDs y DVDs Musicales'
        WHEN 'casa_construcao' THEN 'Materiales de Construcción'
        WHEN 'casa_conforto_2' THEN 'Confort del Hogar 2'
        WHEN 'artigos_de_natal' THEN 'Artículos de Navidad'
        WHEN 'artes_e_artesanato' THEN 'Arte y Artesanía'
        WHEN 'agro_industria_e_comercio' THEN 'Agroindustria y Comercio'
        
        -- Categorías principales:
        WHEN 'cama_mesa_banho' THEN 'Cama, Mesa y Baño'
        WHEN 'beleza_saude' THEN 'Belleza y Salud'
        WHEN 'esporte_lazer' THEN 'Deportes y Ocio'
        WHEN 'informatica_acessorios' THEN 'Informática y Accesorios'
        WHEN 'utilidades_domesticas' THEN 'Artículos del Hogar'
        WHEN 'relogios_presentes' THEN 'Relojes y Regalos'
        WHEN 'telefonia' THEN 'Telefonía'
        WHEN 'ferramentas_jardim' THEN 'Herramientas y Jardín'
        WHEN 'automotivo' THEN 'Automotriz'
        WHEN 'brinquedos' THEN 'Juguetes'
        WHEN 'cool_stuff' THEN 'Tendencias y Novedades'
        WHEN 'perfumaria' THEN 'Perfumería'
        WHEN 'bebes' THEN 'Bebés'
        WHEN 'eletronicos' THEN 'Electrónica'
        WHEN 'papelaria' THEN 'Papelería y Oficina'
        WHEN 'fashion_bolsas_e_acessorios' THEN 'Moda, Bolsos y Accesorios'
        WHEN 'pet_shop' THEN 'Mascotas'
        WHEN 'moveis_decoracao' THEN 'Muebles y Decoración'
        WHEN 'consoles_games' THEN 'Consolas y Videojuegos'
        WHEN 'instrumentos_musicais' THEN 'Instrumentos Musicales'
        WHEN 'construcao_ferramentas_construcao' THEN 'Construcción y Herramientas'
        WHEN 'eletrodomesticos' THEN 'Electrodomésticos'
        WHEN 'mala_sinalizacao' THEN 'Maletas y Señalización'
        WHEN 'alimentos' THEN 'Alimentos'
        WHEN 'bebidas' THEN 'Bebidas'
        WHEN 'audio' THEN 'Audio'
        WHEN 'moveis_escritorio' THEN 'Muebles de Oficina'
        WHEN 'market_place' THEN 'Marketplace'
        WHEN 'construcao_ferramentas_iluminacao' THEN 'Iluminación y Construcción'
        WHEN 'fashion_calcados' THEN 'Calzado'
        WHEN 'artigos_de_festas' THEN 'Artículos de Fiesta'
        WHEN 'casa_conforto' THEN 'Confort del Hogar'
        WHEN 'livros_interesse_geral' THEN 'Libros de Interés General'
        WHEN 'alimentos_bebidas' THEN 'Alimentos y Bebidas'
        WHEN 'flores' THEN 'Flores'
        WHEN 'fashion_underwear_e_moda_praia' THEN 'Ropa Interior y Playa'
        
        ELSE UPPER(LEFT(REPLACE(ISNULL(p.product_category_name, 'Sin Categoría'), '_', ' '), 1)) + 
             SUBSTRING(REPLACE(ISNULL(p.product_category_name, 'Sin Categoría'), '_', ' '), 2, 100)
    END AS categoria_producto,
    TRY_CAST(o.order_purchase_timestamp AS DATETIME2) AS fecha_compra,
    TRY_CAST(o.order_delivered_customer_date AS DATETIME2) AS fecha_entrega_cliente,
    TRY_CAST(o.order_estimated_delivery_date AS DATETIME2) AS fecha_estimada_entrega,
    i.price / 100.0 AS precio,
    i.freight_value / 100.0 AS flete,
    r.review_score
FROM olist_orders_dataset o
INNER JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
INNER JOIN olist_order_items_dataset i ON o.order_id = i.order_id
LEFT JOIN olist_products_dataset p ON i.product_id = p.product_id
LEFT JOIN olist_order_reviews_dataset r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered';

GO
SELECT DISTINCT categoria_producto 
FROM vw_ventas_consolidadas
ORDER BY categoria_producto ASC;