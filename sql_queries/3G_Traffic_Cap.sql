select [Date],
GROUP_CONCAT(case when Zone = 'Central'  then TotalTraffic end) as Central_Traffic,
GROUP_CONCAT(case when Zone = 'Central'  then CapOffer end) as Central_Cap,
GROUP_CONCAT(case when Zone = 'North'  then TotalTraffic end) as North_Traffic,
GROUP_CONCAT(case when Zone = 'North'  then CapOffer end) as North_Cap,
GROUP_CONCAT(case when Zone = 'South'  then TotalTraffic end) as South_Traffic,
GROUP_CONCAT(case when Zone = 'South'  then CapOffer end) as South_Cap
from(
select [Date], Zone, sum([Traffic (MB)]) as TotalTraffic, sum([Capacit Offered]) as CapOffer
from dailydata
where [Date] > date('now','-31 day')
group by Zone, [Date])
group by [Date]