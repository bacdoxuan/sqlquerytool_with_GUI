SELECT [Date], [Zone], [Province], [Tech], round(sum([Average HSPA Users]),2) as "HSDPA User", round(avg([HSDPA user throughput (Mbps)])/1000,2) as "Avg Throughput", round(sum([PS Traffic WD (Mb)])/1024/1024,2) as "Traffic (TB)", round(sum([CS Traffic WD (Erl)]),2) as "Voice (Erl)"
FROM DailyData
WHERE [Date] > date('now','-31 day')
GROUP BY [Date], [Province], [Tech];