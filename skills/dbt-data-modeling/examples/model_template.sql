{{
    config(
        materialized='view',
        tags=['staging', 'ecommerce']
    )
}}

/*
    Model: stg_ecommerce__orders
    Description: Staging model for raw e-commerce orders with defensive CDC deduplication,
                 soft delete filtering, and status enum mapping.
*/

with

-- 1. Import CTE
source_data as (

    select * from {{ source('ecommerce', 'raw_orders') }}

),

-- 2. Logical CTE (Renaming, Type Casting, Defensive Mapping)
renamed_and_cleaned as (

    select
        -- Primary Key
        cast(id as string) as order_id,

        -- Foreign Keys
        cast(customer_id as string) as customer_id,

        -- Attributes with Defensive Bucketing
        case
            when lower(trim(status)) in ('placed', 'processing', 'shipped', 'delivered', 'cancelled', 'returned')
                then lower(trim(status))
            when status is null then 'unspecified'
            else 'other'
        end as order_status,

        -- Numeric Metrics
        coalesce(cast(subtotal_cents as numeric) / 100.0, 0.0) as subtotal_amount_usd,

        -- Timestamps
        cast(ordered_at as timestamp) as ordered_at,
        cast(_fivetran_synced as timestamp) as _fivetran_synced,
        cast(_fivetran_deleted as boolean) as is_deleted

    from source_data
    where _fivetran_deleted is false

),

-- 3. Window Deduplication CTE (For CDC / At-Least-Once streams)
deduplicated as (

    select *
    from renamed_and_cleaned
    qualify row_number() over (
        partition by order_id
        order by _fivetran_synced desc
    ) = 1

),

-- 4. Final CTE
final as (

    select
        order_id,
        customer_id,
        order_status,
        subtotal_amount_usd,
        ordered_at,
        _fivetran_synced

    from deduplicated

)

-- 5. Final Select
select * from final
