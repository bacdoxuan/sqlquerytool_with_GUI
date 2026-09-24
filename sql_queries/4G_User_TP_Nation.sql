select [Start Time], round(sum([LTE User Peak]),2), round(avg([LTE throughput Peak]),2)
FROM DailyData
WHERE [Start Time] > date('now','-32 day')
GROUP BY [Start Time]