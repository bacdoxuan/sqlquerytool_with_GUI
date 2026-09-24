select [Date], [Zone], [Province],
group_concat(case when [Tech] = 'U2100' then physicalSite end) as U2100_site,
group_concat(case when [Tech] = 'U900' then physicalSite end) as U900_site
from
(
select [Date], [Zone], [Province], [Tech], count(SiteID) as physicalSite
from
(
select distinct [Date], [Zone], [Province], [Tech], substr([UCell Id],2,6) as SiteID
from dailydata
where [Date] = date('now','-1 day')
)
group by [Province], [Tech]
)
group by [Province]
;