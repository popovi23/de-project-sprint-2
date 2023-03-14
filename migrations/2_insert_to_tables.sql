-- Заполнение справочника стоимости доставки в страны
INSERT INTO shipping_country_rates(
    shipping_country,
    shipping_country_base_rate
)
SELECT DISTINCT 
    s.shipping_country, s.shipping_country_base_rate
FROM shipping s;


-- Заполнение справочника тарифов доставки вендора по договору
WITH description_array AS (
    SELECT DISTINCT 
        regexp_split_to_array(vendor_agreement_description, ':') AS desc_arr
    FROM shipping
)
INSERT INTO shipping_agreement
SELECT
    desc_arr[1]::bigint,
    desc_arr[2],
    desc_arr[3]::numeric,
    desc_arr[4]::numeric
FROM description_array;


-- Заполнение справочника о типах доставки
WITH description_array AS (
    SELECT DISTINCT
        regexp_split_to_array(shipping_transfer_description, ':') AS desc_array,
        shipping_transfer_rate
    FROM shipping
)
INSERT INTO shipping_transfer(
    shipping_transfer_type,
    shipping_transfer_model,
    shipping_transfer_rate
)
SELECT
    description_array.desc_array[1],
    description_array.desc_array[2],
    shipping_transfer_rate
FROM description_array;


-- Заполнение таблицы с уникальными доставками

-- 1. На время импорта данных удалим ограничения
ALTER TABLE shipping_info DROP CONSTRAINT IF EXISTS shipping_info_pkey;
ALTER TABLE shipping_info DROP CONSTRAINT IF EXISTS  shipping_info_agreement_id_fkey;
ALTER TABLE shipping_info DROP CONSTRAINT IF EXISTS shipping_info_shipping_country_id_fkey;
ALTER TABLE shipping_info DROP CONSTRAINT IF EXISTS shipping_info_transfer_id_fkey;

-- 2. Импорт данных
WITH sa AS (
    SELECT DISTINCT
        shippingid,
        vendorid,
        payment_amount,
        shipping_plan_datetime,
        regexp_split_to_array(shipping_transfer_description, ':') AS transfer_description_arr,
        regexp_split_to_array(vendor_agreement_description, ':') AS agreement_description_arr,
        shipping_country
    FROM shipping
)
INSERT INTO shipping_info
SELECT
    shippingid,
    vendorid,
    payment_amount,
    shipping_plan_datetime,
    st.shipping_transfer_id,
    sc.shipping_country_id,
    agreement_description_arr[1]::bigint
FROM sa
JOIN shipping_transfer st ON
    st.shipping_transfer_type  = sa.transfer_description_arr[1] AND
    st.shipping_transfer_model = sa.transfer_description_arr[2]
JOIN shipping_country_rates sc ON
    sc.shipping_country = sa.shipping_country;

-- 3. Восстановим ограничения
ALTER TABLE shipping_info ADD constraint shipping_info_pkey
    PRIMARY KEY (shipping_id);
ALTER TABLE shipping_info ADD CONSTRAINT shipping_info_agreement_id_fkey FOREIGN KEY (agreement_id)
    REFERENCES shipping_agreement(agreement_id) ON UPDATE CASCADE;
ALTER TABLE shipping_info ADD CONSTRAINT shipping_info_shipping_country_id_fkey FOREIGN KEY (shipping_country_id)
    REFERENCES  shipping_country_rates(shipping_country_id) ON UPDATE CASCADE;
ALTER TABLE shipping_info ADD CONSTRAINT shipping_info_transfer_id_fkey FOREIGN KEY (transfer_id)
    REFERENCES shipping_transfer(shipping_transfer_id) ON UPDATE CASCADE;


-- Заполнение таблицы статусов о доставке
INSERT INTO shipping_status
    SELECT DISTINCT
	    shippingid,
		max(state_datetime) FILTER(WHERE state='booked') OVER idw shipping_start_fact_datetime,
		max(state_datetime) FILTER(WHERE state='recieved') OVER idw shipping_end_fact_datetime,
		first_value(status) OVER max_sort max_status,
		first_value(state) OVER max_sort max_state
    FROM shipping
    WINDOW max_sort AS (PARTITION BY shippingid ORDER BY state_datetime DESC),
    idw AS (PARTITION BY shippingid);
