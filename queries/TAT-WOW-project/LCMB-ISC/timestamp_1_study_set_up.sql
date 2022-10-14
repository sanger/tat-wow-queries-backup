SELECT  -- SQL_NO_CACHE
        DISTINCT
        relevant_samples.ewh_sample_id
        ,relevant_samples.sample_uuid_bin
        ,relevant_samples.sample_uuid
        ,relevant_samples.sample_friendly_name
        ,sub.id AS ewh_study_id
        ,sub.uuid AS study_uuid_bin
        ,insert(insert(insert(insert(lower(hex(sub.uuid)),9,0,'-'),14,0,'-'),19,0,'-'),24,0,'-') AS study_uuid
        ,sub.friendly_name AS study_friendly_name
        ,studies.created AS study_set_up
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
;