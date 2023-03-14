-- Удаляем таблицы
DROP VIEW IF EXISTS shipping_datamart;
DROP TABLE IF EXISTS shipping_info;
DROP TABLE IF EXISTS shipping_status;
DROP TABLE IF EXISTS shipping_country_rates;
DROP TABLE IF EXISTS shipping_agreement;
DROP TABLE IF EXISTS shipping_transfer;


-- Создание справочника стоимости доставки в страны
CREATE TABLE shipping_country_rates(
    shipping_country_id serial PRIMARY KEY,
    shipping_country text,
    shipping_country_base_rate NUMERIC(14,3)
);
CREATE INDEX shipping_country_rates_i ON shipping_country_rates(shipping_country);
COMMENT ON COLUMN shipping_country_rates.shipping_country_id is 'Уникальный идентификатор страны доставки';
COMMENT ON COLUMN shipping_country_rates.shipping_country is 'Страна доставки';
COMMENT ON COLUMN shipping_country_rates.shipping_country_base_rate is 'Налог на доставку в страну';

-- Создание справочника тарифов доставки вендора по договору
CREATE TABLE shipping_agreement(
    agreement_id bigint PRIMARY KEY,
    agreement_number text,
    agreement_rate NUMERIC(2,2),
    agreement_commission NUMERIC(2,2)
);
COMMENT ON COLUMN shipping_agreement.agreement_id is 'Уникальный идентификатор договора';
COMMENT ON COLUMN shipping_agreement.agreement_number is 'Номер договора в бухгалтерии';
COMMENT ON COLUMN shipping_agreement.agreement_rate is 'Ставка налога за стоимость доставки товара для вендора';
COMMENT ON COLUMN shipping_agreement.agreement_commission is 'Комиссия - доля в платеже являющаяся доходом компании от сделки';

-- Создание справочника о типах доставки
CREATE TABLE shipping_transfer(
    shipping_transfer_id serial PRIMARY KEY,
    shipping_transfer_type text,
    shipping_transfer_model text,
    shipping_transfer_rate NUMERIC(14,3)
);
COMMENT ON COLUMN shipping_transfer.shipping_transfer_id is 'Уникальный справочник типа доставки';
COMMENT ON COLUMN shipping_transfer.shipping_transfer_type is 'Тип доставки';
COMMENT ON COLUMN shipping_transfer.shipping_transfer_model is 'Модель доставки - способ, которым заказ доставляется до точки';
COMMENT ON COLUMN shipping_transfer.shipping_transfer_rate is 'Процент стоимости доставки для вендора';

-- Создание таблицы с уникальными доставками
CREATE TABLE shipping_info(
    shipping_id bigint PRIMARY KEY,
    vendor_id bigint,
    payment_amount NUMERIC(14,2),
    shipping_plan_datetime timestamp,
	FOREIGN KEY (transfer_type_id) REFERENCES shipping_transfer (shipping_transfer_type_id) on update cascade,
	FOREIGN KEY (shipping_country_id) REFERENCES shipping_country_rates (shipping_country_id) on update cascade,
	FOREIGN KEY (agreement_id) REFERENCES shipping_agreement (agreement_id) on update cascade
);
COMMENT ON COLUMN shipping_info.shipping_id is 'Уникальный идентификатор доставки';
COMMENT ON COLUMN shipping_info.vendor_id is 'Уникальный идентификатор вендора';
COMMENT ON COLUMN shipping_info.payment_amount is 'Сумма платежа';
COMMENT ON COLUMN shipping_info.shipping_plan_datetime is 'Плановая дата доставки';
COMMENT ON COLUMN shipping_info.transfer_id is 'ID типа доставки';
COMMENT ON COLUMN shipping_info.shipping_country_id is 'ID страны доставки';
COMMENT ON COLUMN shipping_info.agreement_id is 'ID тарифа';

-- Создание таблицы статусов о доставке
CREATE TABLE shipping_status(
    shipping_id bigint PRIMARY KEY,
    shipping_start_fact_datetime timestamp,
    shipping_end_fact_datetime timestamp,
    "status" text,
    "state" text
);
COMMENT ON COLUMN shipping_status.shipping_id is 'Уникальный идентификатор доставки';
COMMENT ON COLUMN shipping_status.shipping_start_fact_datetime is 'Фактическая дата начала доставки';
COMMENT ON COLUMN shipping_status.shipping_end_fact_datetime is 'Фактическая дата окончания доставки';
COMMENT ON COLUMN shipping_status.status is 'Статус доставки ';
COMMENT ON COLUMN shipping_status.state is 'Состояние доставки';