select [Date], round(sum([Average HSPA Users]),2), round(avg([HSDPA user throughput (Mbps)]),2)
FROM DailyData
WHERE [Date] > date('now','-31 day')
GROUP BY [Date]