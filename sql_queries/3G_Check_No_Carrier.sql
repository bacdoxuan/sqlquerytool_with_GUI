select [Date], Zone, sum([Carrier/site])
from DailyData
where [Date] > date('now', '-31 day')
group by Zone, [Date]