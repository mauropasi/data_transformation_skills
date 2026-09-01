{{
    config(
        materialized='table',
        tags=['marts', 'finance']
    )
}}

/*
    Model: fct_orders
    Description: Core fact table representing customer orders at the order-grain.
    Grain: One row per order_id.
*/

with

-- 1. Import CTEs
orders as (

    select * from {{ ref('stg_ecommerce__orders') }}

),

order_items_aggregated as (

    select * from {{ ref('int_order_items__aggregated') }}

),

payments_pivoted as (

    select * from {{ ref('int_payments__pivoted_by_order') }}

),

-- 2. Logical CTEs
joined as (

    select
        -- Primary Key
        orders.order_id,

        -- Foreign Keys
        orders.customer_id,
        orders.store_id,

        -- Order Attributes
        orders.order_status,
        orders.channel_code,

        -- Aggregated Metrics (from intermediate models)
        coalesce(order_items_aggregated.total_item_count, 0) as total_item_count,
        coalesce(order_items_aggregated.subtotal_amount_usd, 0.0) as subtotal_amount_usd,
        coalesce(payments_pivoted.credit_card_amount_usd, 0.0) as credit_card_amount_usd,
        coalesce(payments_pivoted.gift_card_amount_usd, 0.0) as gift_card_amount_usd,
        coalesce(payments_pivoted.total_paid_amount_usd, 0.0) as total_paid_amount_usd,

        -- Order Timestamps
        orders.ordered_at,
        orders.shipped_at,
        orders.delivered_at,
        orders.created_at

    from orders
    left join order_items_aggregated
        on orders.order_id = order_items_aggregated.order_id
    left join payments_pivoted
        on orders.order_id = payments_pivoted.order_id

),

-- 3. Final CTE
final as (

    select
        order_id,
        customer_id,
        store_id,
        order_status,
        channel_code,
        total_item_count,
        subtotal_amount_usd,
        credit_card_amount_usd,
        gift_card_amount_usd,
        total_paid_amount_usd,

        -- Calculated Flag
        case
            when total_paid_amount_usd >= subtotal_amount_usd then true
            else false
        end as is_fully_paid,

        ordered_at,
        shipped_at,
        delivered_at,
        created_at

    from joined

)

-- 4. Final Select
select * from final
