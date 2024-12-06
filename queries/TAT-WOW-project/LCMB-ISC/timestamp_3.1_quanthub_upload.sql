SELECT  -- SQL_NO_CACHE
        relevant_samples.ewh_sample_id
        ,relevant_samples.sample_uuid_bin
        ,relevant_samples.sample_uuid
        ,relevant_samples.sample_friendly_name
        ,MIN(qc.date_created) AS 'sample_management_qc_result_date'
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

JOIN mlwhd_mlwarehouse_proddata.sample mlwh_sample ON mlwh_sample.uuid_sample_lims = relevant_samples.sample_uuid
JOIN mlwhd_mlwarehouse_proddata.qc_result qc USING (id_sample_tmp)

WHERE qc.labware_purpose = 'Stock Plate' AND qc.assay = 'Stock - Plate Reader v1.0'

GROUP BY relevant_samples.ewh_sample_id, relevant_samples.sample_uuid_bin, relevant_samples.sample_uuid, relevant_samples.sample_friendly_name
;

-- only returns 16 rows, as it looks like only one of our plates in the range we're checking went through Sample Management