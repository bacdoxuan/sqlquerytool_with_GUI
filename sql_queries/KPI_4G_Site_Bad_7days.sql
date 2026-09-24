-- Bad Site 4G 7 days

-- Site has at least one KPI bad
with bad_cell_7days_4G as 
(
SELECT A.Zone,
       A.Province,
       A.Site_Id,
       round(100.0 * sum(A.RRC_success) / sum(A.RRC_att) * sum(A.Erab_est_suc_init) / sum(A.Erab_est_att_init) * sum(A.S1_signal_success) / sum(A.S1_signal_attempt), 2) AS [4G Data CSSR],
       round(avg(nullif(A.[erab_Abnormal_release_rate(%)], 0)), 2) AS [4G Data CDR],
       round(avg( nullif(A.[CSFB_SR_%], 0) ), 2) AS [4G CSFB Rate],
       round(100.0 * sum(A.[VoLTE_AE-RAB_Succ_QCI1]) / sum(A.[VoLTE_AE-RAB_Att_QCI1]), 2) AS [4G VoLTE CSSR],
       round(100.0 * sum(A.VoLTE_Call_Drop_QCI1) / sum(A.[VoLTE_AE-RAB_Succ_QCI1]), 2) AS [4G VoLTE CDR],
       round(100.0 * sum(A.DL_PRB_Numerator) / sum(A.DL_PRB_Denominator), 2) AS [4G DL PRB Utilization],
       round(100.0 * sum(A.UL_PRB_Numerator) / sum(A.UL_PRB_Denominator), 2) AS [4G UL PRB Utilization],
       round(avg(nullif(A.[Availability(%)], 0)), 2) AS [4G Availability]
  FROM KPI_4G A
       LEFT JOIN
       site_status B ON A.Site_Id = B.[Site ID]
 WHERE A.Date > date('now', '-8 day')
 GROUP BY A.Zone,
          A.Province,
          A.Site_Id
HAVING A.Zone NOT IN ('#N/A', '#VALUE!') and
([4G Data CSSR] < 99 or [4G Data CDR] > 1.2 or [4G CSFB Rate] < 99 or [4G Availability] < 95) AND
       B.Status = 'On Air'
)
select 
Zone,Province,Site_Id,
[4G Data CSSR],
[4G Data CDR],
[4G CSFB Rate],
[4G VoLTE CSSR],
[4G VoLTE CDR],
[4G DL PRB Utilization],
[4G UL PRB Utilization],
[4G Availability],
case when [4G Data CSSR] < 99 then '4G PS CSSR Fail' else '-' End [4G_ps_cssr],
case when [4G Data CDR] > 1.2 then '4G PS CDR Fail' else '-' END [4G_ps_cdr],
case when [4G CSFB Rate] < 99 then '4G CSFB Fail' else '-' End [4G_csfb],
case when [4G Availability] < 95 then '4G avail Fail' else '-' End [4G_avail],
(case when [4G Data CSSR] < 99 then 1 else 0 End +
case when [4G Data CDR] > 1.2 then 1 else 0 END +
case when [4G CSFB Rate] < 99 then 1 else 0 End +
case when [4G Availability] < 95 then 1 else 0 End) as [4G KPI Fail count]
from bad_cell_7days_4G
order by [4G KPI Fail count] desc;