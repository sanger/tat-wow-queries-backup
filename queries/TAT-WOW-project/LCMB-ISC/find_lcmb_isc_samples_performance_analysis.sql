-- Making the base sample query as a view would help with readability in the other queries.


-- Version 1 - 529 samples, 14 seconds
--
SELECT subject_uuid
FROM
(
  (
    SELECT DISTINCT(fev.subject_uuid)
    FROM metadata m
    JOIN flat_events_view fev ON m.event_id = fev.wh_event_id
    WHERE m.`key` = 'order_type' AND m.value = 'LCMB'
      AND m.created_at > '2022-05-10'
      AND fev.role_type = 'sample'
  )
  UNION ALL
  (
    SELECT DISTINCT(fev.subject_uuid)
    FROM metadata m
    JOIN flat_events_view fev ON m.event_id = fev.wh_event_id
    WHERE m.`key` = 'order_type' AND m.value = 'ReISC'
      AND m.created_at > '2022-05-10'
      AND fev.role_type = 'sample'
  )
) AS all_lcmb_reisc_samples
GROUP BY subject_uuid
HAVING Count(*) > 1
;


-- Version 2 - not using flat_events_view - 529 samples, 11 seconds
--
SELECT id
FROM
(
  (
    SELECT DISTINCT(s.id)
    FROM metadata m
    JOIN events e ON e.id = m.event_id
    JOIN roles r ON r.event_id = e.id
    JOIN role_types rt ON r.role_type_id = rt.id
    JOIN subjects s ON s.id = r.subject_id
    WHERE m.`key` = 'order_type' AND m.value = 'LCMB'
      AND m.created_at > '2022-05-10'
      AND rt.`key` = 'sample'
  )
  UNION ALL
  (
    SELECT DISTINCT(s.id)
    FROM metadata m
    JOIN events e ON e.id = m.event_id
    JOIN roles r ON r.event_id = e.id
    JOIN role_types rt ON r.role_type_id = rt.id
    JOIN subjects s ON s.id = r.subject_id
    WHERE m.`key` = 'order_type' AND m.value = 'ReISC'
      AND m.created_at > '2022-05-10'
      AND rt.`key` = 'sample'
  )
) AS all_lcmb_reisc_samples
GROUP BY id
HAVING Count(*) > 1
;


-- Version 3 - querying both order_types in one - 529 samples, 6 seconds! :)
--
SELECT all_lcmb_reisc_samples_by_pipeline.sample_id
FROM
(
  SELECT DISTINCT s.id AS sample_id, m.value AS pipeline
  FROM metadata m
  JOIN events e ON e.id = m.event_id
  JOIN roles r ON r.event_id = e.id
  JOIN role_types rt ON r.role_type_id = rt.id
  JOIN subjects s ON s.id = r.subject_id
  WHERE m.`key` = 'order_type' AND m.value IN ('LCMB', 'ReISC')
    AND m.created_at > '2022-05-10'
    AND rt.`key` = 'sample'
) AS all_lcmb_reisc_samples_by_pipeline
GROUP BY all_lcmb_reisc_samples_by_pipeline.sample_id
HAVING Count(*) > 1
;

-- Version 4 - including event type filter - 529 samples, 2 seconds! :)
--
  SELECT all_lcmb_reisc_samples_by_pipeline.sample_id
  FROM
  (
    SELECT DISTINCT s.id AS sample_id, m.value AS pipeline
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
  GROUP BY all_lcmb_reisc_samples_by_pipeline.sample_id
  HAVING Count(*) > 1
;

-- Version 5 - including more useful information - 529 samples, still 2ish seconds
--
SELECT ewh_sample_id, sample_uuid_bin, sample_uuid, sample_friendly_name
FROM
(
  SELECT DISTINCT s.id AS ewh_sample_id,
                  s.uuid AS sample_uuid_bin,
                  insert(insert(insert(insert(lower(hex(s.uuid)),9,0,'-'),14,0,'-'),19,0,'-'),24,0,'-') AS sample_uuid,
                  s.friendly_name AS sample_friendly_name,
                  m.value AS pipeline
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
;
