select [Start Time], [Zone], [Province],
GROUP_CONCAT(case when [Tech] = 'L2100' then LTE_Traffic end) as 'L2100',
GROUP_CONCAT(case when [Tech] = 'L900' then LTE_Traffic end) as 'L900'
from
(
select [Start Time], [Zone], [Province], [Tech], sum([LTE Traffic Daily (MB)]) as LTE_Traffic
from dailydata
WHERE [Start Time] > date('now','-32 day')
group by [Start Time], [Province], [Tech]
)
group by [Start Time], [Province]
order by [Province];