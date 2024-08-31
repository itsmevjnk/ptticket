PREPARE insert_fare_duration(int, int) AS INSERT INTO "static"."FareDurations" VALUES ($1, $2);

EXECUTE insert_fare_duration(1, 120);
EXECUTE insert_fare_duration(2, 120);
EXECUTE insert_fare_duration(3, 150);
EXECUTE insert_fare_duration(4, 150);
EXECUTE insert_fare_duration(5, 150);
EXECUTE insert_fare_duration(6, 180);
EXECUTE insert_fare_duration(7, 180);
EXECUTE insert_fare_duration(8, 180);
EXECUTE insert_fare_duration(9, 210);
EXECUTE insert_fare_duration(10, 210);
EXECUTE insert_fare_duration(11, 210);
EXECUTE insert_fare_duration(12, 240);
EXECUTE insert_fare_duration(13, 240);
EXECUTE insert_fare_duration(14, 240);
EXECUTE insert_fare_duration(15, 270);
