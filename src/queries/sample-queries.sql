SELECT 
    timestamp, 
    src_ip, 
    dst_ip, 
    action, 
    count(*) AS event_count 
FROM 
    logs 
WHERE 
    timestamp >= now() - interval 1 day 
GROUP BY 
    timestamp, src_ip, dst_ip, action 
ORDER BY 
    event_count DESC 
LIMIT 100;

SELECT 
    src_ip, 
    count(*) AS total_events 
FROM 
    logs 
WHERE 
    action = 'blocked' 
GROUP BY 
    src_ip 
ORDER BY 
    total_events DESC 
LIMIT 50;

SELECT 
    dst_ip, 
    count(*) AS attack_attempts 
FROM 
    logs 
WHERE 
    action = 'attack' 
GROUP BY 
    dst_ip 
HAVING 
    attack_attempts > 10 
ORDER BY 
    attack_attempts DESC;