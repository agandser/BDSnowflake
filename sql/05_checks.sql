WITH counts AS (
    SELECT 1 AS sort_order, 'raw_mock_data' AS table_name, COUNT(*) AS row_count FROM raw_mock_data
    UNION ALL
    SELECT 2, 'dim_location', COUNT(*) FROM dim_location
    UNION ALL
    SELECT 3, 'dim_pet', COUNT(*) FROM dim_pet
    UNION ALL
    SELECT 4, 'dim_product_category', COUNT(*) FROM dim_product_category
    UNION ALL
    SELECT 5, 'dim_customer', COUNT(*) FROM dim_customer
    UNION ALL
    SELECT 6, 'dim_seller', COUNT(*) FROM dim_seller
    UNION ALL
    SELECT 7, 'dim_store', COUNT(*) FROM dim_store
    UNION ALL
    SELECT 8, 'dim_supplier', COUNT(*) FROM dim_supplier
    UNION ALL
    SELECT 9, 'dim_product', COUNT(*) FROM dim_product
    UNION ALL
    SELECT 10, 'fact_sale', COUNT(*) FROM fact_sale
)
SELECT table_name, row_count
FROM counts
ORDER BY sort_order;

SELECT
    pc.pet_category,
    COUNT(*) AS sales_count,
    ROUND(SUM(fs.sale_total_price), 2) AS revenue
FROM fact_sale AS fs
JOIN dim_product AS p
    ON p.product_id = fs.product_id
JOIN dim_product_category AS pc
    ON pc.category_id = p.category_id
GROUP BY pc.pet_category
ORDER BY revenue DESC, pc.pet_category;
