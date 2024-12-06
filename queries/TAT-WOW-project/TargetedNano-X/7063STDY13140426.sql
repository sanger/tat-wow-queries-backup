SELECT distinct s.friendly_name, et.key, et.description, e.created_at, m.key, m.value
    FROM metadata m
    JOIN events e ON e.id = m.event_id
    JOIN event_types et ON et.id = e.event_type_id
    JOIN roles r ON r.event_id = e.id
    JOIN role_types rt ON r.role_type_id = rt.id
    JOIN subjects s ON s.id = r.subject_id
    WHERE 
      s.friendly_name = '6543STDY10459601'
      AND rt.`key` = 'sample'
	order by e.created_at