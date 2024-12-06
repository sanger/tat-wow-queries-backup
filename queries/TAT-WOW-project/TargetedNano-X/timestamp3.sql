-- based on 'find_stock_plate.sql'

SELECT  -- SQL_NO_CACHE
        relevant_samples.ewh_sample_id
        ,relevant_samples.sample_uuid_bin
        ,relevant_samples.sample_uuid
        ,relevant_samples.sample_friendly_name
        ,sr.labware_human_barcode
        ,sub_stock.id
        ,e.occured_at AS stock_plate_received
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
JOIN mlwhd_mlwarehouse_proddata.stock_resource sr USING (id_sample_tmp)

JOIN subjects sub_stock ON sub_stock.friendly_name = sr.labware_human_barcode -- trying to join on uuid is a lot slower
JOIN roles r_stock ON r_stock.subject_id = sub_stock.id
JOIN events e ON e.id = r_stock.event_id
JOIN event_types et ON et.id = e.event_type_id

WHERE et.`key` = 'slf_receive_plates'
;


-- find MAX date, to get just 1 row per sample
SELECT  relevant_samples.ewh_sample_id
        ,relevant_samples.sample_uuid_bin
        ,relevant_samples.sample_uuid
        ,relevant_samples.sample_friendly_name
        ,sr.labware_human_barcode
        ,sub_stock.id
        ,MAX(e.occured_at) AS stock_plate_received_latest
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

  -- WHERE iseq_flowcell.primer_panel IN ('PFA_GRC1_v1.0', 'PFA_GRC2_v1.0', 'PFA_Spec', 'PVIV_GRC_1.0')
) AS relevant_samples

JOIN mlwhd_mlwarehouse_proddata.sample mlwh_sample ON mlwh_sample.uuid_sample_lims = relevant_samples.sample_uuid
JOIN mlwhd_mlwarehouse_proddata.stock_resource sr USING (id_sample_tmp)

JOIN subjects sub_stock ON sub_stock.friendly_name = sr.labware_human_barcode -- trying to join on uuid is a lot slower
JOIN roles r_stock ON r_stock.subject_id = sub_stock.id
JOIN events e ON e.id = r_stock.event_id
JOIN event_types et ON et.id = e.event_type_id

WHERE et.`key` = 'slf_receive_plates'

GROUP BY relevant_samples.ewh_sample_id
;