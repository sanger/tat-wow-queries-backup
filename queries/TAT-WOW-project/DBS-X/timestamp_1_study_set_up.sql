-- study name and timestamp concatenated, so get one row per sample
SELECT  relevant_samples.ewh_sample_id
        ,relevant_samples.sample_uuid_bin
        ,relevant_samples.sample_uuid
        ,relevant_samples.sample_friendly_name
        ,GROUP_CONCAT(DISTINCT(sub.friendly_name)) AS study_friendly_names
        ,GROUP_CONCAT(DISTINCT(studies.created)) AS studies_set_up
FROM
(
  -- All samples that have had a GbS submission, and have been sequenced using a relevant primer panel
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
      AND m.value = 'Limber-Htp - GBS'
      AND rt.`key` = 'sample'
  ) as gbs_samples

  JOIN mlwhd_mlwarehouse_proddata.sample mlwh_sample ON mlwh_sample.uuid_sample_lims = gbs_samples.sample_uuid
  JOIN mlwhd_mlwarehouse_proddata.iseq_flowcell iseq_flowcell USING (id_sample_tmp)

  WHERE iseq_flowcell.primer_panel IN ('PFA_GRC1_v1.0', 'PFA_GRC2_v1.0', 'PFA_Spec', 'PVIV_GRC_1.0')
) AS relevant_samples

-- Find all order_made events for the relevant samples (1,837 rows, 54 distinct events)
LEFT JOIN roles r_sample ON r_sample.subject_id = relevant_samples.ewh_sample_id
LEFT JOIN events e ON e.id = r_sample.event_id
LEFT JOIN event_types et ON et.id = e.event_type_id

-- Find any 'study' subjects associated with these events
LEFT JOIN roles r ON r.event_id = e.id
LEFT JOIN role_types rt ON rt.id = r.role_type_id
LEFT JOIN subjects sub ON r.subject_id = sub.id

-- Join to MLWH study table to get timestamp of Study creation in Sequencescape
LEFT JOIN mlwhd_mlwarehouse_proddata.study studies ON insert(insert(insert(insert(lower(hex(sub.uuid)),9,0,'-'),14,0,'-'),19,0,'-'),24,0,'-') = studies.uuid_study_lims

WHERE et.`key` = 'order_made'
  AND rt.`key` = 'study'

GROUP BY relevant_samples.ewh_sample_id
        ,relevant_samples.sample_uuid_bin
        ,relevant_samples.sample_uuid
        ,relevant_samples.sample_friendly_name

ORDER BY relevant_samples.sample_friendly_name
;