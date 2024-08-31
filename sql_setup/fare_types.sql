PREPARE insert_fare_type(int, varchar(24)) AS INSERT INTO "static"."FareTypes" VALUES ($1, $2);
PREPARE insert_fare_cap(int, int, int) AS INSERT INTO "static"."DailyFareCaps" VALUES (0, $1, $2), (1, $1, $3);

EXECUTE insert_fare_type(0, 'Full Fare');
EXECUTE insert_fare_cap(0, 1060, 720);

EXECUTE insert_fare_type(1, 'Concession');
EXECUTE insert_fare_cap(1, 720, 360);

EXECUTE insert_fare_type(2, 'Child');
EXECUTE insert_fare_cap(2, 720, 360);

EXECUTE insert_fare_type(3, 'Carers');
EXECUTE insert_fare_cap(3, 720, 360);
INSERT INTO "static"."DailyFareCaps" VALUES (2, 3, 0);

EXECUTE insert_fare_type(4, 'Disability Support Pension');
EXECUTE insert_fare_cap(4, 720, 360);

EXECUTE insert_fare_type(5, 'Seniors');
EXECUTE insert_fare_cap(5, 720, 360);
INSERT INTO "static"."DailyFareCaps" VALUES (4, 5, 0);

EXECUTE insert_fare_type(6, 'War Veterans/Widow(er)s');
EXECUTE insert_fare_cap(6, 720, 360);
INSERT INTO "static"."DailyFareCaps" VALUES (8, 6, 0);
