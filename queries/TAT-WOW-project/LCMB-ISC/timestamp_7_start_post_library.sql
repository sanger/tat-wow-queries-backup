-- Sequencescape

-- Creation of the LB Lib PCR-XP plate:
-- table 'labware', 'created_at' field - linked to 'plate_purposes' table, where 'name' field is 'LB Lib PCR-XP'.


SELECT relevant_samples.sample_id, GROUP_CONCAT(l.id)
FROM

(
  -- Equivalent of Events WH query identifying (529) LCMB-ISC samples, but using SS db.
  SELECT sample_id, sample_uuid
  FROM

  (
    SELECT DISTINCT s.id AS 'sample_id', u.external_id AS 'sample_uuid', o_r.role AS 'pipeline'

    FROM orders o

    JOIN order_roles o_r ON o_r.id = o.order_role_id
    JOIN asset_groups a_g ON a_g.id = o.asset_group_id
    JOIN asset_group_assets a_g_a ON a_g_a.asset_group_id = a_g.id
    JOIN receptacles r ON a_g_a.asset_id = r.id
    JOIN aliquots a ON r.id = a.receptacle_id
    JOIN samples s ON s.id = a.sample_id
    JOIN uuids u ON u.resource_type = 'sample' AND u.resource_id = s.id

    WHERE o_r.role IN ('LCMB', 'ReISC')
      AND o.created_at > '2022-05-10'
  ) AS all_lcmb_reisc_samples_by_pipeline

  GROUP BY sample_id
    HAVING Count(*) > 1
) AS relevant_samples

JOIN aliquots a ON relevant_samples.sample_id = a.sample_id
JOIN receptacles r ON r.id = a.receptacle_id
JOIN labware l ON l.id = r.labware_id
JOIN plate_purposes pp ON pp.id = l.plate_purpose_id

WHERE pp.name = 'LB Lib PCR-XP'

GROUP BY relevant_samples.sample_id
;
-- 1,058 rows
-- All 529 samples represented
-- 2 LB Lib PCR-XP plates for each sample - one seems to be cherrypicked into the other
