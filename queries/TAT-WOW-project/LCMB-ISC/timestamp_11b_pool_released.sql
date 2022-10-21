-- bear in mind library_complete & pool_released changed meaning on 27/06/2022

SELECT  ewh_sample_id
        ,sample_uuid_bin
        ,sample_uuid
        ,sample_friendly_name
        ,MAX(e.occured_at) AS pool_released
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

LEFT JOIN roles r ON r.subject_id = relevant_samples.ewh_sample_id
LEFT JOIN events e ON e.id = r.event_id
LEFT JOIN event_types et ON et.id = e.event_type_id
LEFT JOIN metadata m ON m.event_id = e.id

WHERE et.`key` = 'pool_released'
  AND m.`key` = 'order_type' AND m.value = 'ReISC'

GROUP BY ewh_sample_id
;

-- only 453 rows (missing for 76 samples)
-- pool_released event not fired for NT1756559V, NT1756560O & NT1756561P (22 x 3 = 66 samples), presumably because they were made on 27 June, which is the day the deployment was done on
-- pool_released event not present for NT1764717O (remaining 10 samples, and some which are not on the LCMB-ISC list), not sure why