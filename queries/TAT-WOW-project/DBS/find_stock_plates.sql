SELECT  relevant_samples.ewh_sample_id
        ,relevant_samples.sample_uuid_bin
        ,relevant_samples.sample_uuid
        ,relevant_samples.sample_friendly_name
        ,sr.labware_human_barcode
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

JOIN mlwhd_mlwarehouse_proddata.sample mlwh_sample ON mlwh_sample.uuid_sample_lims = relevant_samples.sample_uuid
JOIN mlwhd_mlwarehouse_proddata.stock_resource sr USING (id_sample_tmp)

ORDER BY relevant_samples.sample_friendly_name
;

-- distinct stock plate barcodes (52):
-- 'DN889383T','DN906212B','DN901114D','DN906213C','DN889403G','DN889402F','DN906214D','DN873164E','DN889381R','DN873165F','DN873163D','DN889382S','DN833219F','DN833224C','DN833218E','DN824038B','DN824034U','DN824040S','DN824036W','DN824037A','DN824039C','DN906215E','DN890237C','DN906216F','DN901115E','DN946556T','DN906217G','DN903543F','DN944685T','DN944686U','DN944687V','DN944689A','DN944690Q','DN944688W','DN944691R','SQPP-2639-H','SQPP-106-M','SQPP-2634-C','SQPP-2635-D','SQPP-2636-E','DN946555S','DN946553Q','DN946554R','SQPP-101-H','SQPP-102-I','SQPP-104-K','SQPP-103-J','SQPP-105-L','SQPP-2637-F','SQPP-2643-D','SQPP-2638-G','SQPP-2645-F',
-- stock plate barcodes match up nicely to those from WIP spreadsheet.
-- In the WIP, if the "pre-extracted plate" column is filled out, these barcodes map to that column, otherwise they map to the "stock plate" column.
-- All above barcodes are found in the WIP, either in "GbS" or "GbS Complete" tabs.
-- From spot-checking, it looks like any barcodes in the WIP that are *not* in the above list are because of the time window looked at in the query.