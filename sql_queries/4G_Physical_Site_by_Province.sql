select [Start Time], [Zone], [Province], [Tech], count([Site ID]) as Physical_Site
from
    (
    select distinct [Start Time], [Site ID], [Zone], [Province], [Tech]
    from dailydata
    where [Start Time] = date('now','-1 day')
    )
group by [Province], [Tech];