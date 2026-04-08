BEGIN;

DROP TABLE IF EXISTS fact_sale CASCADE;
DROP TABLE IF EXISTS dim_product CASCADE;
DROP TABLE IF EXISTS dim_supplier CASCADE;
DROP TABLE IF EXISTS dim_store CASCADE;
DROP TABLE IF EXISTS dim_seller CASCADE;
DROP TABLE IF EXISTS dim_customer CASCADE;
DROP TABLE IF EXISTS dim_product_category CASCADE;
DROP TABLE IF EXISTS dim_pet CASCADE;
DROP TABLE IF EXISTS dim_location CASCADE;
DROP VIEW IF EXISTS stg_mock_data;

CREATE OR REPLACE VIEW stg_mock_data AS
SELECT
    raw_id,
    NULLIF(BTRIM(source_id), '')::INT AS source_id,
    NULLIF(BTRIM(customer_first_name), '') AS customer_first_name,
    NULLIF(BTRIM(customer_last_name), '') AS customer_last_name,
    NULLIF(BTRIM(customer_age), '')::INT AS customer_age,
    NULLIF(BTRIM(customer_email), '') AS customer_email,
    NULLIF(BTRIM(customer_country), '') AS customer_country,
    NULLIF(BTRIM(customer_postal_code), '') AS customer_postal_code,
    NULLIF(BTRIM(customer_pet_type), '') AS customer_pet_type,
    NULLIF(BTRIM(customer_pet_name), '') AS customer_pet_name,
    NULLIF(BTRIM(customer_pet_breed), '') AS customer_pet_breed,
    NULLIF(BTRIM(seller_first_name), '') AS seller_first_name,
    NULLIF(BTRIM(seller_last_name), '') AS seller_last_name,
    NULLIF(BTRIM(seller_email), '') AS seller_email,
    NULLIF(BTRIM(seller_country), '') AS seller_country,
    NULLIF(BTRIM(seller_postal_code), '') AS seller_postal_code,
    NULLIF(BTRIM(product_name), '') AS product_name,
    NULLIF(BTRIM(product_category), '') AS product_category,
    NULLIF(BTRIM(product_price), '')::NUMERIC(10, 2) AS product_price,
    NULLIF(BTRIM(product_quantity), '')::INT AS product_quantity,
    TO_DATE(NULLIF(BTRIM(sale_date), ''), 'MM/DD/YYYY') AS sale_date,
    NULLIF(BTRIM(sale_customer_id), '')::INT AS sale_customer_id,
    NULLIF(BTRIM(sale_seller_id), '')::INT AS sale_seller_id,
    NULLIF(BTRIM(sale_product_id), '')::INT AS sale_product_id,
    NULLIF(BTRIM(sale_quantity), '')::INT AS sale_quantity,
    NULLIF(BTRIM(sale_total_price), '')::NUMERIC(12, 2) AS sale_total_price,
    NULLIF(BTRIM(store_name), '') AS store_name,
    NULLIF(BTRIM(store_location), '') AS store_location,
    NULLIF(BTRIM(store_city), '') AS store_city,
    NULLIF(BTRIM(store_state), '') AS store_state,
    NULLIF(BTRIM(store_country), '') AS store_country,
    NULLIF(BTRIM(store_phone), '') AS store_phone,
    NULLIF(BTRIM(store_email), '') AS store_email,
    NULLIF(BTRIM(pet_category), '') AS pet_category,
    NULLIF(BTRIM(product_weight), '')::NUMERIC(10, 2) AS product_weight,
    NULLIF(BTRIM(product_color), '') AS product_color,
    NULLIF(BTRIM(product_size), '') AS product_size,
    NULLIF(BTRIM(product_brand), '') AS product_brand,
    NULLIF(BTRIM(product_material), '') AS product_material,
    NULLIF(BTRIM(product_description), '') AS product_description,
    NULLIF(BTRIM(product_rating), '')::NUMERIC(3, 1) AS product_rating,
    NULLIF(BTRIM(product_reviews), '')::INT AS product_reviews,
    TO_DATE(NULLIF(BTRIM(product_release_date), ''), 'MM/DD/YYYY') AS product_release_date,
    TO_DATE(NULLIF(BTRIM(product_expiry_date), ''), 'MM/DD/YYYY') AS product_expiry_date,
    NULLIF(BTRIM(supplier_name), '') AS supplier_name,
    NULLIF(BTRIM(supplier_contact), '') AS supplier_contact,
    NULLIF(BTRIM(supplier_email), '') AS supplier_email,
    NULLIF(BTRIM(supplier_phone), '') AS supplier_phone,
    NULLIF(BTRIM(supplier_address), '') AS supplier_address,
    NULLIF(BTRIM(supplier_city), '') AS supplier_city,
    NULLIF(BTRIM(supplier_country), '') AS supplier_country
FROM raw_mock_data;

CREATE TABLE dim_location (
    location_id BIGSERIAL PRIMARY KEY,
    location_role TEXT NOT NULL,
    country TEXT,
    postal_code TEXT,
    city TEXT,
    state TEXT
);

CREATE TABLE dim_pet (
    pet_id BIGSERIAL PRIMARY KEY,
    pet_type TEXT,
    pet_breed TEXT
);

CREATE TABLE dim_product_category (
    category_id BIGSERIAL PRIMARY KEY,
    category_name TEXT,
    pet_category TEXT
);

CREATE TABLE dim_customer (
    customer_id BIGSERIAL PRIMARY KEY,
    first_name TEXT,
    last_name TEXT,
    age INT,
    email TEXT NOT NULL UNIQUE,
    location_id BIGINT REFERENCES dim_location(location_id),
    pet_id BIGINT REFERENCES dim_pet(pet_id),
    pet_name TEXT
);

CREATE TABLE dim_seller (
    seller_id BIGSERIAL PRIMARY KEY,
    first_name TEXT,
    last_name TEXT,
    email TEXT NOT NULL UNIQUE,
    location_id BIGINT REFERENCES dim_location(location_id)
);

CREATE TABLE dim_store (
    store_id BIGSERIAL PRIMARY KEY,
    store_name TEXT,
    location_line TEXT,
    phone TEXT,
    email TEXT NOT NULL UNIQUE,
    location_id BIGINT REFERENCES dim_location(location_id)
);

CREATE TABLE dim_supplier (
    supplier_id BIGSERIAL PRIMARY KEY,
    supplier_name TEXT,
    contact_name TEXT,
    email TEXT NOT NULL UNIQUE,
    phone TEXT,
    address_line TEXT,
    location_id BIGINT REFERENCES dim_location(location_id)
);

CREATE TABLE dim_product (
    product_id BIGSERIAL PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id BIGINT NOT NULL REFERENCES dim_product_category(category_id),
    stock_quantity INT,
    product_weight NUMERIC(10, 2),
    product_color TEXT,
    product_size TEXT,
    product_brand TEXT,
    product_material TEXT,
    product_description TEXT,
    product_rating NUMERIC(3, 1),
    product_reviews INT,
    product_release_date DATE,
    product_expiry_date DATE
);

CREATE TABLE fact_sale (
    sale_id BIGSERIAL PRIMARY KEY,
    raw_id BIGINT NOT NULL UNIQUE REFERENCES raw_mock_data(raw_id) ON DELETE CASCADE,
    sale_date DATE,
    customer_id BIGINT NOT NULL REFERENCES dim_customer(customer_id),
    seller_id BIGINT NOT NULL REFERENCES dim_seller(seller_id),
    product_id BIGINT NOT NULL REFERENCES dim_product(product_id),
    store_id BIGINT NOT NULL REFERENCES dim_store(store_id),
    supplier_id BIGINT NOT NULL REFERENCES dim_supplier(supplier_id),
    unit_price NUMERIC(10, 2),
    sale_quantity INT,
    sale_total_price NUMERIC(12, 2)
);

CREATE INDEX idx_fact_sale_date ON fact_sale (sale_date);
CREATE INDEX idx_fact_sale_customer ON fact_sale (customer_id);
CREATE INDEX idx_fact_sale_product ON fact_sale (product_id);

COMMIT;
