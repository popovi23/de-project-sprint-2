-- Заполнение справочника стоимости доставки в страны
insert into shipping_country_rates(
    shipping_country,
    shipping_country_base_rate
)
select distinct
    s.shipping_country, s.shipping_country_base_rate
from shipping s;


-- Заполнение справочника тарифов доставки вендора по договору
with description_array as (
    select distinct
        regexp_split_to_array(vendor_agreement_description, ':') as desc_arr
    from shipping
)
insert into shipping_agreement
select
    desc_arr[1]::bigint,
    desc_arr[2],
    desc_arr[3]::numeric,
    desc_arr[4]::numeric
from description_array;


-- Заполнение справочника о типах доставки
with description_array as (
    select distinct
        regexp_split_to_array(shipping_transfer_description, ':') as desc_array,
        shipping_transfer_rate
    from shipping
)
insert into shipping_transfer(
    shipping_transfer_type,
    shipping_transfer_model,
    shipping_transfer_rate
)
select
    description_array.desc_array[1],
    description_array.desc_array[2],
    shipping_transfer_rate
from description_array;


-- Заполнение таблицы с уникальными доставками

-- 1. На время импорта данных удалим ограничения
alter table shipping_info drop constraint if exists shipping_info_pkey;
alter table shipping_info drop constraint if exists shipping_info_agreement_id_fkey;
alter table shipping_info drop constraint if exists shipping_info_shipping_country_id_fkey;
alter table shipping_info drop constraint if exists shipping_info_transfer_id_fkey;

-- 2. Импорт данных
with sa as (
    select distinct
        shippingid,
        vendorid,
        payment_amount,
        shipping_plan_datetime,
        regexp_split_to_array(shipping_transfer_description, ':') as transfer_description_arr,
        regexp_split_to_array(vendor_agreement_description, ':') as agreement_description_arr,
        shipping_country
    from shipping
)
insert into shipping_info
select
    shippingid,
    vendorid,
    payment_amount,
    shipping_plan_datetime,
    st.shipping_transfer_id,
    sc.shipping_country_id,
    agreement_description_arr[1]::bigint
from sa
join shipping_transfer st ON
    st.shipping_transfer_type  = sa.transfer_description_arr[1] and
    st.shipping_transfer_model = sa.transfer_description_arr[2]
join shipping_country_rates sc ON
    sc.shipping_country = sa.shipping_country;

-- 3. Восстановим ограничения
alter table shipping_info add constraint shipping_info_pkey
    PRIMARY KEY (shipping_id);
alter table shipping_info add constraint shipping_info_agreement_id_fkey foreign key (agreement_id)
    references shipping_agreement(agreement_id) on update cascade;
alter table shipping_info add constraint shipping_info_shipping_country_id_fkey foreign key (shipping_country_id)
    references shipping_country_rates(shipping_country_id) on update cascade;
alter table shipping_info add constraint shipping_info_transfer_id_fkey foreign key (transfer_id)
    references shipping_transfer(shipping_transfer_id) on update cascade;


-- Заполнение таблицы статусов о доставке
insert into shipping_status
    select distinct
	    shippingid,
		max(state_datetime) filter(where state='booked') over idw shipping_start_fact_datetime,
		max(state_datetime) filter(where state='recieved') over idw shipping_end_fact_datetime,
		first_value(status) over max_sort max_status,
		first_value(state) over max_sort max_state
    from shipping
    window  max_sort as (partition by shippingid order by state_datetime desc),
    idw as (partition by shippingid);