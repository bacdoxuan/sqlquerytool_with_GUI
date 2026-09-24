select Province, [Sale region], Zone,
group_concat(case when [Date] = date('now', '-8 day') then traffic/1024 end) as day_7,
group_concat(case when [Date] = date('now', '-2 day') then traffic/1024 end) as day_2,
group_concat(case when [Date] = date('now', '-1 day') then traffic/1024 end) as day_1
from
(
select Province, [Sale region], Zone, [Date], sum([Traffic (MB)]) as traffic
from DailyData
Where
[Date] = date('now','-1 day') or [Date] = date('now','-2 day') or [Date] = date('now','-8 day')
group by Province, [Date]
)
group by Province
order by Zone