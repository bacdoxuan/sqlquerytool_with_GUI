select [Date],
SUM(CASE WHEN [Zone] = 'North' THEN [CS Traffic WD (Erl)] ELSE 0 END) as North_cs_traffic,
SUM(CASE WHEN [Zone] = 'Central' THEN [CS Traffic WD (Erl)] ELSE 0 END) as Central_cs_traffic,
SUM(CASE WHEN [Zone] = 'South' THEN [CS Traffic WD (Erl)] ELSE 0 END) as South_cs_traffic
from DailyData
where [Date] > date('now','-31 day')
group by [Date];