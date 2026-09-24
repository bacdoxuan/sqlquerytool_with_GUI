-- 4G Network KPI

SELECT 'Avg 30 days' as 'Network',
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
 WHERE A.Date > date('now', '-31 day') AND
       B.Status = 'On Air';