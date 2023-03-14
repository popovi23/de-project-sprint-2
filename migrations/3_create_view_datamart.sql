CREATE OR REPLACE shipping_datamart AS
SELECT
    si.shipping_id,
    si.vendor_id,
    st.shipping_transfer_type,
    EXTRACT(DAY FROM (shipping_end_fact_datetime - shipping_start_fact_datetime)) AS full_day_at_shipping,
    ss.shipping_end_fact_datetime > si.shipping_plan_datetime is_delay,
    ss.status = 'finished' is_shipping_finish,
    CASE WHEN ss.shipping_end_fact_datetime > si.shipping_plan_datetime
            THEN ss.shipping_end_fact_datetime::date - si.shipping_plan_datetime::date
    END delay_day_at_shipping,
    si.payment_amount,
    si.payment_amount * (scr.shipping_country_base_rate + sag.agreement_rate + st.shipping_transfer_rate) vat,
    si.payment_amount * sag.agreement_commission profit
FROM shipping_info si
JOIN shipping_transfer st ON st.shipping_transfer_id = si.transfer_id
JOIN shipping_status ss ON ss.shipping_id = si.shipping_id
JOIN shipping_agreement sag ON sag.agreement_id = si.agreement_id
JOIN shipping_country_rates scr ON scr.shipping_country_id =  si.shipping_country_id 