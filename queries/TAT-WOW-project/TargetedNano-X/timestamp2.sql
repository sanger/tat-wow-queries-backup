-- 'submission' here means when the customer asks for a batch of work to be completed
-- this happens via the RT system, via the SSRs
-- here we're using sample manifest upload to SS as a proxy

SELECT  ewh_sample_id
        ,sample_uuid_bin
        ,sample_uuid
        ,sample_friendly_name
        ,e.id AS manifest_event_id
        ,e.occured_at AS 'samples_created_by_manifest'
FROM
(
  SELECT DISTINCT s.id AS ewh_sample_id,
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
  
  
) AS relevant_samples

JOIN roles r ON r.subject_id = relevant_samples.ewh_sample_id
JOIN events e ON e.id = r.event_id
JOIN event_types et ON et.id = e.event_type_id

WHERE et.`key` = 'sample_manifest.updated'
;