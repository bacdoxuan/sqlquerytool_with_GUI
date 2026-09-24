select
Province,
group_concat(case when Tech_BW = 'L2100_10Mhz' then cell_count end) as 'L2100_10Mhz',
group_concat(case when Tech_BW = 'L2100_5Mhz' then cell_count end) as 'L2100_5Mhz',
group_concat(case when Tech_BW = 'L900_3Mhz' then cell_count end) as 'L900_3Mhz',
group_concat(case when Tech_BW = 'L900_5Mhz' then cell_count end) as 'L900_5Mhz',
group_concat(case when Tech_BW = 'L900_8Mhz' then cell_count end) as 'L900_8Mhz'
from
    (
    select Province, Tech_BW, count(Tech_BW) as cell_count
    from
        (
        select
        daily.[Start Time] as Date,
        daily.[Province] as Province,
        daily.[Cell Name] as Cell_Name,
        daily.[Tech] || '_' || ifnull(bw.[Bandwidth], "5Mhz") as Tech_BW
            from DailyData daily
            left join Cell_4G_BW bw
            on daily.[Cell Name] = bw.[Cell_Name]
            where daily.[Start Time] = date('now','-1 day')
        )
    group by Province, Tech_BW
    )
group by Province
;