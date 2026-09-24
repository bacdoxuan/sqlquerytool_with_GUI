-- 3G Traffic by Province, Layer
SELECT [Date], [Zone], [Province],
GROUP_CONCAT(case when [Tech] = 'U2100' then sum_traffic end) as 'U2100',
GROUP_CONCAT(case when [Tech] = 'U900' then sum_traffic end) as 'U900'
from
(
select [Date], [Zone], [Province], [Tech], sum([PS Traffic WD (Mb)]) as sum_traffic
from dailydata
WHERE [Date] > date('now','-31 day') 
group by [Date], [Province], [Tech]
)
group by [Date], [Province];