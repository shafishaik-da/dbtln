with raw_reviews as (select * from {{ref("src_hosts")}})
select
   host_id,  host_name, is_superhost, created_at, updated_at
from raw_reviews
where host_id = 12345