select Province,
group_concat(case when Tech_BW = 'L2100_10Mhz' then site_count end) as 'L2100_10Mhz',  
group_concat(case when Tech_BW = 'L2100_5Mhz' then site_count end) as 'L2100_5Mhz',
group_concat(case when Tech_BW = 'L900_3Mhz' then site_count end) as 'L900_3Mhz',  
group_concat(case when Tech_BW = 'L900_5Mhz' then site_count end) as 'L900_5Mhz',
group_concat(case when Tech_BW = 'L900_8Mhz' then site_count end) as 'L900_8Mhz'  
from
( 
select Date, Zone, Province, Tech_BW, count(Site_ID) as site_count
    from
    (
        select distinct
        daily.[Start Time] as Date,
        daily.[Zone] as Zone,
        daily.[Province] as Province,
        substr(daily.[Cell Name],2,6) as Site_ID,
        daily.[Tech] || '_' || ifnull(bw.[Bandwidth], "5Mhz") as Tech_BW
        from DailyData daily
        left join Cell_4G_BW bw
        on daily.[Cell Name] = bw.[Cell_Name]
        where daily.[Start Time] = date('now','-1 day')
        -- limit 1000
    )
group by Province, Tech_BW
)
group by Province
;