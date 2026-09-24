select Zone, [Start Time],
SUM(CASE WHEN Tech = 'L2100' THEN [LTE Traffic Daily (MB)] ELSE 0 END) AS 'L2100',
SUM(CASE WHEN Tech = 'L900' THEN [LTE Traffic Daily (MB)] ELSE 0 END) AS 'L900'
from DailyData
where [Start Time] > date('now','-31 day')
group by Zone, [Start Time];
