SELECT  ewh_sample_id
        ,sample_uuid_bin
        ,sample_uuid
        ,sample_friendly_name
        ,e.id AS reisc_event_id
        ,MIN(e.occured_at) AS 'ReISC_order_made'
FROM
(
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

JOIN roles r ON r.subject_id = relevant_samples.ewh_sample_id
JOIN events e ON e.id = r.event_id
JOIN event_types et ON et.id = e.event_type_id
JOIN metadata m ON m.event_id = e.id

WHERE et.`key` = 'order_made'
  AND m.`key` = 'order_type' AND m.value = 'ReISC'

GROUP BY ewh_sample_id
;