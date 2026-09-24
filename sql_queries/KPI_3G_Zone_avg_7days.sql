-- 3G Zone KPI

SELECT 
       A.Zone,
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
       A.Province NOT IN ('Cao Bang', 'Lai Chau') AND
       B.Status = 'On Air'
 GROUP BY 
          A.Zone
HAVING A.Zone NOT IN ('#N/A', '#VALUE!')
 ORDER BY A.Zone;