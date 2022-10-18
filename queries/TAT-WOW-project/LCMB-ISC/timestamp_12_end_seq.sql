SELECT  relevant_samples.ewh_sample_id
        ,relevant_samples.sample_uuid_bin
        ,relevant_samples.sample_uuid
        ,relevant_samples.sample_friendly_name
        ,iseq_run_status.date
        ,iseq_run_status_dict.description
FROM
(
  -- Relevant (529) samples for LCMB-ISC pipeline
  SELECT ewh_sample_id, sample_uuid_bin, sample_uuid, sample_friendly_name
  FROM
  (
    SELECT DISTINCT s.id AS ewh_sample_id,
                    s.uuid AS sample_uuid_bin,
                    insert(insert(insert(insert(lower(hex(s.uuid)),9,0,'-'),14,0,'-'),19,0,'-'),24,0,'-') AS sample_uuid,
                    s.friendly_name AS sample_friendly_name, m.value AS pipeline
    FROM metadata m
    JOIN events e ON e.id = m.event_id
    JOIN event_types et ON et.id = e.event_type_id
    JOIN roles r ON r.event_id = e.id
    JOIN role_types rt ON r.role_type_id = rt.id
    JOIN subjects s ON s.id = r.subject_id
    WHERE m.`key` = 'order_type' AND m.value IN ('LCMB', 'ReISC')
      AND m.created_at > '2022-05-10'
      AND rt.`key` = 'sample'
      AND et.`key` = 'order_made'
  ) AS all_lcmb_reisc_samples_by_pipeline
  GROUP BY all_lcmb_reisc_samples_by_pipeline.ewh_sample_id
  HAVING Count(*) > 1
) AS relevant_samples

JOIN mlwhd_mlwarehouse_proddata.sample mlwh_sample ON mlwh_sample.uuid_sample_lims = relevant_samples.sample_uuid -- 529
JOIN mlwhd_mlwarehouse_proddata.iseq_flowcell iseq_flowcell USING (id_sample_tmp) -- 1,919 (including at least 1 for every sample)
JOIN mlwhd_mlwarehouse_proddata.iseq_product_metrics iseq_product_metrics USING (id_iseq_flowcell_tmp) -- 1,919
JOIN mlwhd_mlwarehouse_proddata.iseq_run_lane_metrics iseq_run_lane_metrics
	ON iseq_product_metrics.id_run = iseq_run_lane_metrics.id_run
	AND iseq_product_metrics.position = iseq_run_lane_metrics.position -- 1,919
JOIN mlwhd_mlwarehouse_proddata.iseq_run_status iseq_run_status
  ON iseq_run_status.id_run = iseq_run_lane_metrics.id_run -- 26,898
JOIN mlwhd_mlwarehouse_proddata.iseq_run_status_dict iseq_run_status_dict
  ON iseq_run_status_dict.id_run_status_dict = iseq_run_status.id_run_status_dict -- 26,898

-- WHERE iseq_run_status_dict.description = 'run complete' -- 1,919
-- WHERE iseq_run_status_dict.description = 'analysis pending' -- 1,919
-- WHERE iseq_run_status_dict.description = 'analysis complete' -- 1,919
-- WHERE iseq_run_status_dict.description = 'qc review pending' -- 1,919
-- WHERE iseq_run_status_dict.description = 'run archived' -- 1,919
-- WHERE iseq_run_status_dict.description = 'qc complete' -- 1,919
;