select distinct `value` 
from metadata 
where `key`='submission_template' 
	and (lower(`value`) like '%targeted%' or lower(`value`) like '%nano%');