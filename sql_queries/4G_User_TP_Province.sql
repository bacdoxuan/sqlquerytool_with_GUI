select [Start Time], [Zone], [Province], [Tech], round(sum([LTE User Peak]),2) as "4G Active User", round(avg([LTE throughput Peak]),2) as "4G Throughput", round(sum([LTE Traffic Daily (MB)])/1024/1024,2) as "Traffic (TB)"
FROM DailyData
WHERE [Start Time] > date('now','-32 day')
GROUP BY [Start Time], [Province], [Tech];