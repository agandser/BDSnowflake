BEGIN;

TRUNCATE TABLE
    fact_sale,
    dim_product,
    dim_supplier,
    dim_store,
    dim_seller,
    dim_customer,
    dim_product_category,
    dim_pet,
    dim_location
RESTART IDENTITY CASCADE;

INSERT INTO dim_location (location_role, country, postal_code, city, state)
SELECT DISTINCT
    location_role,
    country,
    postal_code,
    city,
    state
FROM (
    SELECT
        'customer' AS location_role,
        customer_country AS country,
        customer_postal_code AS postal_code,
        NULL::TEXT AS city,
        NULL::TEXT AS state
    FROM stg_mock_data
    UNION
    SELECT
        'seller',
        seller_country,
        seller_postal_code,
        NULL::TEXT,
        NULL::TEXT
    FROM stg_mock_data
    UNION
    SELECT
        'store',
        store_country,
        NULL::TEXT,
        store_city,
        store_state
    FROM stg_mock_data
    UNION
    SELECT
        'supplier',
        supplier_country,
        NULL::TEXT,
        supplier_city,
        NULL::TEXT
    FROM stg_mock_data
) AS src
WHERE country IS NOT NULL
   OR postal_code IS NOT NULL
   OR city IS NOT NULL
   OR state IS NOT NULL;

INSERT INTO dim_pet (pet_type, pet_breed)
SELECT DISTINCT
    customer_pet_type,
    customer_pet_breed
FROM stg_mock_data
WHERE customer_pet_type IS NOT NULL
   OR customer_pet_breed IS NOT NULL;

INSERT INTO dim_product_category (category_name, pet_category)
SELECT DISTINCT
    product_category,
    pet_category
FROM stg_mock_data
WHERE product_category IS NOT NULL
   OR pet_category IS NOT NULL;

INSERT INTO dim_customer (
    first_name,
    last_name,
    age,
    email,
    location_id,
    pet_id,
    pet_name
)
SELECT DISTINCT
    m.customer_first_name,
    m.customer_last_name,
    m.customer_age,
    m.customer_email,
    l.location_id,
    p.pet_id,
    m.customer_pet_name
FROM stg_mock_data AS m
LEFT JOIN dim_location AS l
    ON l.location_role = 'customer'
   AND l.country IS NOT DISTINCT FROM m.customer_country
   AND l.postal_code IS NOT DISTINCT FROM m.customer_postal_code
   AND l.city IS NULL
   AND l.state IS NULL
LEFT JOIN dim_pet AS p
    ON p.pet_type IS NOT DISTINCT FROM m.customer_pet_type
   AND p.pet_breed IS NOT DISTINCT FROM m.customer_pet_breed
WHERE m.customer_email IS NOT NULL;

INSERT INTO dim_seller (
    first_name,
    last_name,
    email,
    location_id
)
SELECT DISTINCT
    m.seller_first_name,
    m.seller_last_name,
    m.seller_email,
    l.location_id
FROM stg_mock_data AS m
LEFT JOIN dim_location AS l
    ON l.location_role = 'seller'
   AND l.country IS NOT DISTINCT FROM m.seller_country
   AND l.postal_code IS NOT DISTINCT FROM m.seller_postal_code
   AND l.city IS NULL
   AND l.state IS NULL
WHERE m.seller_email IS NOT NULL;

INSERT INTO dim_store (
    store_name,
    location_line,
    phone,
    email,
    location_id
)
SELECT DISTINCT
    m.store_name,
    m.store_location,
    m.store_phone,
    m.store_email,
    l.location_id
FROM stg_mock_data AS m
LEFT JOIN dim_location AS l
    ON l.location_role = 'store'
   AND l.country IS NOT DISTINCT FROM m.store_country
   AND l.city IS NOT DISTINCT FROM m.store_city
   AND l.state IS NOT DISTINCT FROM m.store_state
   AND l.postal_code IS NULL
WHERE m.store_email IS NOT NULL;

INSERT INTO dim_supplier (
    supplier_name,
    contact_name,
    email,
    phone,
    address_line,
    location_id
)
SELECT DISTINCT
    m.supplier_name,
    m.supplier_contact,
    m.supplier_email,
    m.supplier_phone,
    m.supplier_address,
    l.location_id
FROM stg_mock_data AS m
LEFT JOIN dim_location AS l
    ON l.location_role = 'supplier'
   AND l.country IS NOT DISTINCT FROM m.supplier_country
   AND l.city IS NOT DISTINCT FROM m.supplier_city
   AND l.postal_code IS NULL
   AND l.state IS NULL
WHERE m.supplier_email IS NOT NULL;

INSERT INTO dim_product (
    product_name,
    category_id,
    stock_quantity,
    product_weight,
    product_color,
    product_size,
    product_brand,
    product_material,
    product_description,
    product_rating,
    product_reviews,
    product_release_date,
    product_expiry_date
)
SELECT DISTINCT
    m.product_name,
    pc.category_id,
    m.product_quantity,
    m.product_weight,
    m.product_color,
    m.product_size,
    m.product_brand,
    m.product_material,
    m.product_description,
    m.product_rating,
    m.product_reviews,
    m.product_release_date,
    m.product_expiry_date
FROM stg_mock_data AS m
JOIN dim_product_category AS pc
    ON pc.category_name IS NOT DISTINCT FROM m.product_category
   AND pc.pet_category IS NOT DISTINCT FROM m.pet_category
WHERE m.product_name IS NOT NULL;

INSERT INTO fact_sale (
    raw_id,
    sale_date,
    customer_id,
    seller_id,
    product_id,
    store_id,
    supplier_id,
    unit_price,
    sale_quantity,
    sale_total_price
)
SELECT
    m.raw_id,
    m.sale_date,
    c.customer_id,
    s.seller_id,
    p.product_id,
    st.store_id,
    sp.supplier_id,
    m.product_price,
    m.sale_quantity,
    m.sale_total_price
FROM stg_mock_data AS m
JOIN dim_customer AS c
    ON c.email = m.customer_email
JOIN dim_seller AS s
    ON s.email = m.seller_email
JOIN dim_store AS st
    ON st.email = m.store_email
JOIN dim_supplier AS sp
    ON sp.email = m.supplier_email
JOIN dim_product_category AS pc
    ON pc.category_name IS NOT DISTINCT FROM m.product_category
   AND pc.pet_category IS NOT DISTINCT FROM m.pet_category
JOIN dim_product AS p
    ON p.product_name IS NOT DISTINCT FROM m.product_name
   AND p.category_id = pc.category_id
   AND p.stock_quantity IS NOT DISTINCT FROM m.product_quantity
   AND p.product_weight IS NOT DISTINCT FROM m.product_weight
   AND p.product_color IS NOT DISTINCT FROM m.product_color
   AND p.product_size IS NOT DISTINCT FROM m.product_size
   AND p.product_brand IS NOT DISTINCT FROM m.product_brand
   AND p.product_material IS NOT DISTINCT FROM m.product_material
   AND p.product_description IS NOT DISTINCT FROM m.product_description
   AND p.product_rating IS NOT DISTINCT FROM m.product_rating
   AND p.product_reviews IS NOT DISTINCT FROM m.product_reviews
   AND p.product_release_date IS NOT DISTINCT FROM m.product_release_date
   AND p.product_expiry_date IS NOT DISTINCT FROM m.product_expiry_date
ORDER BY m.raw_id;

COMMIT;
