PREPARE insert_mode(int, varchar(24)) AS INSERT INTO "static"."TransportModes" VALUES ($1, $2);
EXECUTE insert_mode(0, 'None'); -- for non-gate locations
EXECUTE insert_mode(1, 'Bus');
EXECUTE insert_mode(2, 'Tram');
EXECUTE insert_mode(3, 'Train');