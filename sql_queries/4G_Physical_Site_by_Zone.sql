select [Start Time], [Zone], [Tech], count([Site ID]) as Physical_Site
from
    (
    select distinct [Start Time], [Site ID], [Zone], [Tech]
    from dailydata
    where [Start Time] = date('now','-1 day')
    )
group by [Zone], [Tech];