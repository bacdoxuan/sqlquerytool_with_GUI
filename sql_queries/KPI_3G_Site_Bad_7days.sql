-- Bad Site 3G 7 days

-- Site has at least one KPI bad
With bad_cells_7days as(
SELECT 
       A.Zone,
       A.Province,
       A.[RBS Name],
       -- 3G Voice CSSR
       round(100.0 * 
             (sum(A.[CS RRC Success]) * 1.0 / sum(A.[CS RRC Attemp])) * 
             (sum(A.[CS RAB Success]) * 1.0 / sum(A.[CS RAB Attemp])) * 
             CASE 
                 WHEN sum(A.[CS NAS Attemp]) IS NULL OR sum(A.[CS NAS Attemp]) = 0 THEN 1.0
                 ELSE (sum(A.[CS NAS Success]) * 1.0 / sum(A.[CS NAS Attemp]))
             END, 2) AS [3G Voice CSSR],
       round(100.0 * sum(A.[CS Call Drop]) / sum(A.[CS Call Attemp]), 2) AS [3G Voice CDR],
       -- 3G Data CSSR
       round(100.0 * 
             (sum(A.[PS RRC Success]) * 1.0 / sum(A.[PS RRC Attemp])) * 
             (sum(A.[HSDPA Success]) * 1.0 / sum(A.[HSDPA Attemp])) * 
             CASE 
                 WHEN sum(A.[PS NAS Attemp]) IS NULL OR sum(A.[PS NAS Attemp]) = 0 THEN 1.0
                 ELSE (sum(A.[PS NAS Success]) * 1.0 / sum(A.[PS NAS Attemp]))
             END, 2) AS [3G Data CSSR],
       round(100.0 * sum(A.[HSDPA Drop]) / sum(A.[HSDPA Drop Denominator]), 2) AS [3G Data CDR],
       round(1.0 * avg( nullif(A.[Cell Availability (%)],0 ) ), 2) AS [3G Availibility]
  FROM KPI_3G A
       LEFT JOIN
       site_status B ON A.[RBS Name] = B.[Site ID]
 WHERE A.Date > date('now', '-8 day') AND
       A.[Cell Availability (%)] >= 0 AND
       A.Province NOT IN ('Cao Bang', 'Lai Chau')
 GROUP BY 
          A.Zone,
          A.Province,
          A.[RBS Name]
HAVING A.Zone NOT IN ('#N/A', '#VALUE!') 
       and ([3G Voice CSSR] < 99 
            or [3G Voice CDR] > 0.8 
            or [3G Data CSSR] < 98 
            or [3G Data CDR] > 1.5 
            or [3G Availibility] < 95)
		AND
        B.Status = 'On Air'
)
select [Zone], [Province], [RBS Name], 
       [3G Voice CSSR], [3G Voice CDR], 
       [3G Data CSSR], [3G Data CDR], [3G Availibility],
       case when [3G Voice CSSR] < 99 then 'CS CSSR Fail' else '-' END [3G_cs_cssr],
       case when [3G Voice CDR] > 0.8 then 'CS CDR Fail' else '-' END [3G_cs_cdr],
       case when [3G Data CSSR] < 98 then 'PS CSSR Fail' else '-' END [3G_ps_cssr],
       case when [3G Data CDR] > 1.5 then 'PS CDR Fail' else '-' END [3G_ps_cdr],
       case when [3G Availibility] < 95 then '3G avail Fail' else '-' END [G_availability],
       -- Cột đếm số lượng KPI fail
       (case when [3G Voice CSSR] < 99 then 1 else 0 end +
        case when [3G Voice CDR] > 0.8 then 1 else 0 end +
        case when [3G Data CSSR] < 98 then 1 else 0 end +
        case when [3G Data CDR] > 1.5 then 1 else 0 end +
        case when [3G Availibility] < 95 then 1 else 0 end) AS [Failed KPI Count]
from bad_cells_7days
order by [Failed KPI Count] desc;