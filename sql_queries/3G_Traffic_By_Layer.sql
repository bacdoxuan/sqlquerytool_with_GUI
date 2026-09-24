SELECT [Date],
GROUP_CONCAT(case when Tech = 'U2100' then sum_traffic end) as 'U2100',
GROUP_CONCAT(case when Tech = 'U900' then sum_traffic end) as 'U900'
from(
select [Date], Tech, sum([PS Traffic WD (Mb)]) as sum_traffic
from dailydata
WHERE [Date] > date('now','-31 day')
group by Date, Tech)
group by Date