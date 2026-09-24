select zone, [date],
GROUP_CONCAT(case when UR = '<20%' then count_site end) as '<20%',
GROUP_CONCAT(case when UR = '20-40%' then count_site end) as '20-40%',
GROUP_CONCAT(case when UR = '40-60%' then count_site end) as '40-60%',
GROUP_CONCAT(case when UR = '60-80%' then count_site end) as '60-80%',
GROUP_CONCAT(case when UR = '>80%' then count_site end) as '>80%',
sum(count_site) as total_site
from
(
select zone, [date], count([site]) as count_site, [Utilization_range] as UR
from dailydata
WHERE [Date] > date('now','-32 day')
group by zone, [date], [Utilization_range]
)
group by zone, [date]