select [Date], [Zone], [Province], [Tech], count([Site ID]) as Physical_Site
from
(
    select distinct [Site ID], [Zone], [Province], [Tech], [Date]
    from
        (
        select [Date], [UCell Id], substr([UCell Id],2,6) as [Site ID], [Zone], [Province], [Tech]
        from dailydata
        where [Date] = date('now','-1 day')
        )
)
group by [Province], [Tech];