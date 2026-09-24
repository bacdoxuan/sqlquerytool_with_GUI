select Date_report, Zone, sum([Carrier/site])
from DailyData
where Date_report > date('now', '-31 day')
group by Zone, Date_report