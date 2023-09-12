-- Modified LCMB-ISC timestamp_12_end_seq.sql

SELECT  relevant_samples.sample_uuid
        ,relevant_samples.sample_friendly_name
        ,iseq_run_status_dict.description
        ,MAX(iseq_run_status.date)
FROM
(
  SELECT DISTINCT ewh_sample_id, sample_uuid_bin, sample_uuid, sample_friendly_name
  FROM
  (
  SELECT  DISTINCT s.id AS ewh_sample_id,
          s.uuid AS sample_uuid_bin,
          insert(insert(insert(insert(lower(hex(s.uuid)),9,0,'-'),14,0,'-'),19,0,'-'),24,0,'-') AS sample_uuid,
          s.friendly_name AS sample_friendly_name
    FROM metadata m
    JOIN events e ON e.id = m.event_id
    JOIN event_types et ON et.id = e.event_type_id
    JOIN roles r ON r.event_id = e.id
    JOIN role_types rt ON r.role_type_id = rt.id
    JOIN subjects s ON s.id = r.subject_id
    WHERE m.created_at BETWEEN '2022-05-10' AND '2022-11-01'
      AND et.`key` = 'order_made'
      AND m.`key` = 'submission_template'
      AND m.value = 'Limber-Htp - Targeted NanoSeq'
      AND rt.`key` = 'sample'
  ) as targeted_nano_samples

  JOIN mlwhd_mlwarehouse_proddata.sample mlwh_sample ON mlwh_sample.uuid_sample_lims = targeted_nano_samples.sample_uuid
  JOIN mlwhd_mlwarehouse_proddata.iseq_flowcell iseq_flowcell USING (id_sample_tmp)
  
) AS relevant_samples

JOIN mlwhd_mlwarehouse_proddata.sample mlwh_sample ON mlwh_sample.uuid_sample_lims = relevant_samples.sample_uuid -- 529 sample rows
JOIN mlwhd_mlwarehouse_proddata.iseq_flowcell iseq_flowcell USING (id_sample_tmp) -- 545 iseq_flowcell rows (1 for each 'Twist Pulldown' sample, 2 for each 'Agilent Pulldown' sample because they were run on two lanes)
JOIN mlwhd_mlwarehouse_proddata.iseq_product_metrics iseq_product_metrics USING (id_iseq_flowcell_tmp)
JOIN mlwhd_mlwarehouse_proddata.iseq_run_lane_metrics iseq_run_lane_metrics
	ON iseq_product_metrics.id_run = iseq_run_lane_metrics.id_run
	AND iseq_product_metrics.position = iseq_run_lane_metrics.position
JOIN mlwhd_mlwarehouse_proddata.iseq_run_status iseq_run_status
  ON iseq_run_status.id_run = iseq_run_lane_metrics.id_run
JOIN mlwhd_mlwarehouse_proddata.iseq_run_status_dict iseq_run_status_dict
  ON iseq_run_status_dict.id_run_status_dict = iseq_run_status.id_run_status_dict

WHERE
	relevant_samples.sample_friendly_name = '6752STDY12998988'

 -- iseq_run_status_dict.description IN (
   -- Check for Step 10 start of seq.
   -- 'run_pending',
   -- 'run_in_progress',
   
   -- end check
  --  'run complete', 
   -- 'analysis pending', 
    -- 'analysis complete', 
    -- 'qc review pending', 
    -- 'run archived', 
    -- 'qc complete'
   -- )

GROUP BY relevant_samples.sample_uuid, iseq_run_status_dict.description
ORDER BY sample_friendly_name, MAX(iseq_run_status.date)
;