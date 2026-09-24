select
[Province], 
group_concat(case when [Tech] = 'U2100' then cell_count end) as 'U2100',
group_concat(case when [Tech] = 'U900' then cell_count end) as 'U900'
from
(
select [Date], [Zone], [Province], [Tech], count([UCell Id]) as cell_count
from DailyData
where [Date] = date('now','-1 day')
group by [Province], [Tech]
)
group by [Province]