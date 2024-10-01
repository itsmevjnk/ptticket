-- init.sql
DROP DATABASE IF EXISTS "ptticket";
CREATE DATABASE "ptticket";

DROP GROUP IF EXISTS "ptticket";
CREATE GROUP "ptticket";
DROP USER IF EXISTS "static";
DROP USER IF EXISTS "dynamic";
DROP USER IF EXISTS "auth";
CREATE USER "static" ENCRYPTED PASSWORD 'ptticket_static' IN GROUP "ptticket";
CREATE USER "dynamic" ENCRYPTED PASSWORD 'ptticket_dynamic' IN GROUP "ptticket";
CREATE USER "auth" ENCRYPTED PASSWORD 'ptticket_auth' IN GROUP "ptticket";

-- tables.sql
CREATE EXTENSION pgcrypto;

CREATE SCHEMA "static" AUTHORIZATION "static";
CREATE SCHEMA "dynamic" AUTHORIZATION "dynamic";

CREATE TABLE "static"."FareTypes" (
    "type" INTEGER PRIMARY KEY,
    "name" VARCHAR(48) NOT NULL
);

CREATE TABLE "static"."Products" (
    "id" INTEGER PRIMARY KEY,
    "name" VARCHAR(48) NOT NULL,
    "fromZone" INTEGER NOT NULL,
    "toZone" INTEGER NOT NULL,
    "duration" INTEGER NOT NULL
);

CREATE TABLE "static"."TransactionTypes" (
    "type" INTEGER PRIMARY KEY,
    "name" VARCHAR(48) NOT NULL
);

CREATE TABLE "static"."SpecialDates" (
    "from" DATE NOT NULL,
    "to" DATE NOT NULL,
    "dateCondition" INTEGER NOT NULL,
    "description" VARCHAR(48),
    PRIMARY KEY ("from", "to")
);

CREATE TABLE "static"."TransportModes" (
    "mode" INTEGER PRIMARY KEY,
    "name" VARCHAR(24) NOT NULL
);

CREATE TABLE "static"."Locations" (
    "id" SERIAL PRIMARY KEY,
    "name" VARCHAR(64),
    "mode" INTEGER REFERENCES "static"."TransportModes" ("mode"),
    "minProduct" INTEGER REFERENCES "static"."Products" ("id"),
    "defaultProduct" INTEGER REFERENCES "static"."Products" ("id")
);

CREATE TABLE "static"."ProductFares" (
    "productID" INTEGER REFERENCES "static"."Products" ("id"),
    "fareType" INTEGER REFERENCES "static"."FareTypes" ("type"),
    "dateCondition" INTEGER,
    "fare" INTEGER NOT NULL,
    PRIMARY KEY ("productID", "fareType", "dateCondition")
);

CREATE TABLE "static"."DailyFareCaps" (
    "dateCondition" INTEGER,
    "fareType" INTEGER REFERENCES "static"."FareTypes" ("type"),
    "fareCap" INTEGER NOT NULL,
    PRIMARY KEY ("dateCondition", "fareType")
);

CREATE TABLE "dynamic"."Tickets" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "fareType" INTEGER REFERENCES "static"."FareTypes" ("type"),
    "balance" INTEGER NOT NULL DEFAULT (0),
    "dailyExpenditure" INTEGER NOT NULL DEFAULT (0),
    "currentProduct" INTEGER REFERENCES "static"."Products" ("id") DEFAULT (0),
    "touchedOn" INTEGER REFERENCES "static"."Products" ("id") DEFAULT (0),
    "prodValidated" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "prodDuration" INTEGER NOT NULL DEFAULT (0)
);

CREATE TABLE "dynamic"."Transactions" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "ticketID" UUID REFERENCES "dynamic"."Tickets" ("id"),
    "timestamp" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "type" INTEGER REFERENCES "static"."TransactionTypes" ("type"),
    "location" INTEGER REFERENCES "static"."Locations" ("id"),
    "product" INTEGER REFERENCES "static"."Products" ("id"),
    "balance" INTEGER NOT NULL
);

CREATE TABLE "dynamic"."PhysicalTickets" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "type" VARCHAR(8) NOT NULL,
    "disabled" BOOLEAN NOT NULL DEFAULT (FALSE),
    "expiryDate" DATE,
    "ticketID" UUID REFERENCES "dynamic"."Tickets" ("id")
);

CREATE TABLE "dynamic"."Passes" (
    "transactionID" UUID PRIMARY KEY REFERENCES "dynamic"."Transactions" ("id"),
    "ticketID" UUID REFERENCES "dynamic"."Tickets" ("id"),
    "duration" INTEGER NOT NULL,
    "activationDate" DATE,
    "product" INTEGER REFERENCES "static"."Products" ("id")
);

GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES ON ALL TABLES IN SCHEMA "static" TO "static";
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES ON ALL TABLES IN SCHEMA "dynamic" TO "dynamic";

GRANT SELECT ON ALL TABLES IN SCHEMA "dynamic" TO "static";
GRANT SELECT ON ALL TABLES IN SCHEMA "static" TO "dynamic";

GRANT USAGE ON SCHEMA "static" TO "static";
GRANT USAGE ON SCHEMA "dynamic" TO "dynamic";
GRANT USAGE ON SCHEMA "dynamic" TO "static";
GRANT USAGE ON SCHEMA "static" TO "dynamic";

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "static" TO "static";
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "dynamic" TO "dynamic";

GRANT USAGE ON ALL SEQUENCES IN SCHEMA "static" TO "static";
GRANT USAGE ON ALL SEQUENCES IN SCHEMA "dynamic" TO "dynamic";

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "dynamic" TO "static";
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "static" TO "dynamic";

CREATE SCHEMA "auth" AUTHORIZATION "auth";

CREATE TABLE "auth"."Keys" (
    "key" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "timestamp" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES ON ALL TABLES IN SCHEMA "auth" TO "auth";
GRANT USAGE ON SCHEMA "auth" TO "auth";
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "auth" TO "auth";
GRANT USAGE ON ALL SEQUENCES IN SCHEMA "auth" TO "auth";

-- modes.sql
PREPARE insert_mode(int, varchar(24)) AS INSERT INTO "static"."TransportModes" VALUES ($1, $2);
EXECUTE insert_mode(0, 'None'); -- for non-gate locations
EXECUTE insert_mode(1, 'Bus');
EXECUTE insert_mode(2, 'Tram');
EXECUTE insert_mode(3, 'Train');

-- special_dates.sql
PREPARE insert_special_date_1(date, integer, varchar(48)) AS INSERT INTO "static"."SpecialDates" VALUES ($1, $1, $2, $3);
PREPARE insert_special_date_n(date, date, integer, varchar(48)) AS INSERT INTO "static"."SpecialDates" VALUES ($1, $2, $3, $4);

-- 2024 public holidays (https://business.vic.gov.au/business-information/public-holidays/victorian-public-holidays-2024)
EXECUTE insert_special_date_1('2024-01-01', 1, 'New Year''s Day');
EXECUTE insert_special_date_1('2024-01-26', 1, 'Australia Day');
EXECUTE insert_special_date_1('2024-03-11', 1, 'Labour Day');
EXECUTE insert_special_date_1('2024-03-29', 1, 'Good Friday');
EXECUTE insert_special_date_1('2024-03-30', 1, 'Saturday before Easter Sunday');
EXECUTE insert_special_date_1('2024-03-31', 1, 'Easter Sunday');
EXECUTE insert_special_date_1('2024-04-01', 1, 'Easter Monday');
EXECUTE insert_special_date_1('2024-04-25', 9, 'ANZAC Day'); -- also commemorative day
EXECUTE insert_special_date_1('2024-06-10', 1, 'King''s Birthday');
EXECUTE insert_special_date_1('2024-09-27', 1, 'Friday before the AFL Grand Final');
EXECUTE insert_special_date_1('2024-11-05', 1, 'Melbourne Cup');
EXECUTE insert_special_date_1('2024-12-25', 1, 'Christmas Day');
EXECUTE insert_special_date_1('2024-12-26', 1, 'Boxing Day');

-- Military commemorative dates (https://anzacportal.dva.gov.au/commemoration/days)
EXECUTE insert_special_date_1('2024-02-19', 8, 'Bombing of Darwin Day');
EXECUTE insert_special_date_1('2024-05-08', 8, 'Victory in Europe (VE) Day');
EXECUTE insert_special_date_1('2024-07-27', 8, 'Korean Veterans'' Day');
EXECUTE insert_special_date_1('2024-08-15', 8, 'Victory in the Pacific (VP) Day');
EXECUTE insert_special_date_1('2024-08-18', 8, 'Vietnam Veterans'' Day');
EXECUTE insert_special_date_1('2024-08-31', 8, 'Malaya and Borneo Veterans'' Day');
EXECUTE insert_special_date_1('2024-09-03', 8, 'Merchant Navy Day');
EXECUTE insert_special_date_1('2024-09-04', 8, 'Battle for Australia Day');
EXECUTE insert_special_date_1('2024-09-14', 8, 'National Peacekeepers'' Day');
EXECUTE insert_special_date_1('2024-11-11', 8, 'Remembrance Day');

-- Weeks
EXECUTE insert_special_date_n('2024-10-13', '2024-10-19', 2, 'National Carers'' Week');
EXECUTE insert_special_date_n('2024-10-13', '2024-10-20', 8, 'Veterans'' Health Week');

EXECUTE insert_special_date_n('2024-10-06', '2024-10-13', 4, 'Victorian Seniors Festival');

-- transaction_types.sql
PREPARE insert_transaction_type(int, varchar(24)) AS INSERT INTO "static"."TransactionTypes" VALUES ($1, $2);

EXECUTE insert_transaction_type(0, 'Touch on');
EXECUTE insert_transaction_type(1, 'Touch off');
EXECUTE insert_transaction_type(2, 'Touch off and on');
EXECUTE insert_transaction_type(3, 'Failed touch off');
EXECUTE insert_transaction_type(4, 'Top up');
EXECUTE insert_transaction_type(5, 'Pass purchase');

-- fare_types.sql
PREPARE insert_fare_type(int, varchar(24)) AS INSERT INTO "static"."FareTypes" VALUES ($1, $2);
PREPARE insert_fare_cap(int, int, int) AS INSERT INTO "static"."DailyFareCaps" VALUES (0, $1, $2), (1, $1, $3);

EXECUTE insert_fare_type(0, 'Full Fare');
EXECUTE insert_fare_cap(0, 1060, 720);

EXECUTE insert_fare_type(1, 'Concession');
EXECUTE insert_fare_cap(1, 530, 360);

EXECUTE insert_fare_type(2, 'Child');
EXECUTE insert_fare_cap(2, 530, 360);

EXECUTE insert_fare_type(3, 'Carers');
EXECUTE insert_fare_cap(3, 530, 360);
INSERT INTO "static"."DailyFareCaps" VALUES (2, 3, 0);

EXECUTE insert_fare_type(4, 'Disability Support Pension');
EXECUTE insert_fare_cap(4, 530, 360);

EXECUTE insert_fare_type(5, 'Seniors');
EXECUTE insert_fare_cap(5, 530, 360);
INSERT INTO "static"."DailyFareCaps" VALUES (4, 5, 0);

EXECUTE insert_fare_type(6, 'War Veterans/Widow(er)s');
EXECUTE insert_fare_cap(6, 530, 360);
INSERT INTO "static"."DailyFareCaps" VALUES (8, 6, 0);

-- products.sql
PREPARE insert_product(int, varchar(24), int, int, int) AS INSERT INTO "static"."Products" VALUES ($1, $2, $3, $4, $5);
EXECUTE insert_product(0, 'None', 0, 0, 120);
EXECUTE insert_product(1, 'Zone 1+2', 1, 2, 120);
EXECUTE insert_product(2, 'Zone 1+2+3', 1, 3, 150);
EXECUTE insert_product(3, 'Zone 1/2 overlap', 0, 0, 120);
EXECUTE insert_product(4, 'Zones 1-15', 1, 15, 270);
EXECUTE insert_product(5, 'Zone 2', 2, 2, 120);
EXECUTE insert_product(6, 'Zone 3', 3, 3, 120);
EXECUTE insert_product(7, 'Zone 4', 4, 4, 120);
EXECUTE insert_product(8, 'Zone 5', 5, 5, 120);
EXECUTE insert_product(9, 'Zone 6', 6, 6, 120);
EXECUTE insert_product(10, 'Zone 7', 7, 7, 120);
EXECUTE insert_product(11, 'Zone 8', 8, 8, 120);
EXECUTE insert_product(12, 'Zone 9', 9, 9, 120);
EXECUTE insert_product(13, 'Zone 10', 10, 10, 120);
EXECUTE insert_product(14, 'Zone 11', 11, 11, 120);
EXECUTE insert_product(15, 'Zone 12', 12, 12, 120);
EXECUTE insert_product(16, 'Zone 13', 13, 13, 120);
EXECUTE insert_product(17, 'Zone 14', 14, 14, 120);
EXECUTE insert_product(18, 'Zone 15', 15, 15, 120);
EXECUTE insert_product(19, 'Zones 2-3', 2, 3, 120);
EXECUTE insert_product(20, 'Zones 3-4', 3, 4, 120);
EXECUTE insert_product(21, 'Zones 4-5', 4, 5, 120);
EXECUTE insert_product(22, 'Zones 5-6', 5, 6, 120);
EXECUTE insert_product(23, 'Zones 6-7', 6, 7, 120);
EXECUTE insert_product(24, 'Zones 7-8', 7, 8, 120);
EXECUTE insert_product(25, 'Zones 8-9', 8, 9, 120);
EXECUTE insert_product(26, 'Zones 9-10', 9, 10, 120);
EXECUTE insert_product(27, 'Zones 10-11', 10, 11, 120);
EXECUTE insert_product(28, 'Zones 11-12', 11, 12, 120);
EXECUTE insert_product(29, 'Zones 12-13', 12, 13, 120);
EXECUTE insert_product(30, 'Zones 13-14', 13, 14, 120);
EXECUTE insert_product(31, 'Zones 14-15', 14, 15, 120);
EXECUTE insert_product(32, 'Zones 2-4', 2, 4, 150);
EXECUTE insert_product(33, 'Zones 3-5', 3, 5, 150);
EXECUTE insert_product(34, 'Zones 4-6', 4, 6, 150);
EXECUTE insert_product(35, 'Zones 5-7', 5, 7, 150);
EXECUTE insert_product(36, 'Zones 6-8', 6, 8, 150);
EXECUTE insert_product(37, 'Zones 7-9', 7, 9, 150);
EXECUTE insert_product(38, 'Zones 8-10', 8, 10, 150);
EXECUTE insert_product(39, 'Zones 9-11', 9, 11, 150);
EXECUTE insert_product(40, 'Zones 10-12', 10, 12, 150);
EXECUTE insert_product(41, 'Zones 11-13', 11, 13, 150);
EXECUTE insert_product(42, 'Zones 12-14', 12, 14, 150);
EXECUTE insert_product(43, 'Zones 13-15', 13, 15, 150);
EXECUTE insert_product(44, 'Zones 2-5', 2, 5, 150);
EXECUTE insert_product(45, 'Zones 3-6', 3, 6, 150);
EXECUTE insert_product(46, 'Zones 4-7', 4, 7, 150);
EXECUTE insert_product(47, 'Zones 5-8', 5, 8, 150);
EXECUTE insert_product(48, 'Zones 6-9', 6, 9, 150);
EXECUTE insert_product(49, 'Zones 7-10', 7, 10, 150);
EXECUTE insert_product(50, 'Zones 8-11', 8, 11, 150);
EXECUTE insert_product(51, 'Zones 9-12', 9, 12, 150);
EXECUTE insert_product(52, 'Zones 10-13', 10, 13, 150);
EXECUTE insert_product(53, 'Zones 11-14', 11, 14, 150);
EXECUTE insert_product(54, 'Zones 12-15', 12, 15, 150);
EXECUTE insert_product(55, 'Zones 2-6', 2, 6, 150);
EXECUTE insert_product(56, 'Zones 3-7', 3, 7, 150);
EXECUTE insert_product(57, 'Zones 4-8', 4, 8, 150);
EXECUTE insert_product(58, 'Zones 5-9', 5, 9, 150);
EXECUTE insert_product(59, 'Zones 6-10', 6, 10, 150);
EXECUTE insert_product(60, 'Zones 7-11', 7, 11, 150);
EXECUTE insert_product(61, 'Zones 8-12', 8, 12, 150);
EXECUTE insert_product(62, 'Zones 9-13', 9, 13, 150);
EXECUTE insert_product(63, 'Zones 10-14', 10, 14, 150);
EXECUTE insert_product(64, 'Zones 11-15', 11, 15, 150);
EXECUTE insert_product(65, 'Zones 2-7', 2, 7, 180);
EXECUTE insert_product(66, 'Zones 3-8', 3, 8, 180);
EXECUTE insert_product(67, 'Zones 4-9', 4, 9, 180);
EXECUTE insert_product(68, 'Zones 5-10', 5, 10, 180);
EXECUTE insert_product(69, 'Zones 6-11', 6, 11, 180);
EXECUTE insert_product(70, 'Zones 7-12', 7, 12, 180);
EXECUTE insert_product(71, 'Zones 8-13', 8, 13, 180);
EXECUTE insert_product(72, 'Zones 9-14', 9, 14, 180);
EXECUTE insert_product(73, 'Zones 10-15', 10, 15, 180);
EXECUTE insert_product(74, 'Zones 2-8', 2, 8, 180);
EXECUTE insert_product(75, 'Zones 3-9', 3, 9, 180);
EXECUTE insert_product(76, 'Zones 4-10', 4, 10, 180);
EXECUTE insert_product(77, 'Zones 5-11', 5, 11, 180);
EXECUTE insert_product(78, 'Zones 6-12', 6, 12, 180);
EXECUTE insert_product(79, 'Zones 7-13', 7, 13, 180);
EXECUTE insert_product(80, 'Zones 8-14', 8, 14, 180);
EXECUTE insert_product(81, 'Zones 9-15', 9, 15, 180);
EXECUTE insert_product(82, 'Zones 2-9', 2, 9, 180);
EXECUTE insert_product(83, 'Zones 3-10', 3, 10, 180);
EXECUTE insert_product(84, 'Zones 4-11', 4, 11, 180);
EXECUTE insert_product(85, 'Zones 5-12', 5, 12, 180);
EXECUTE insert_product(86, 'Zones 6-13', 6, 13, 180);
EXECUTE insert_product(87, 'Zones 7-14', 7, 14, 180);
EXECUTE insert_product(88, 'Zones 8-15', 8, 15, 180);
EXECUTE insert_product(89, 'Zones 2-10', 2, 10, 210);
EXECUTE insert_product(90, 'Zones 3-11', 3, 11, 210);
EXECUTE insert_product(91, 'Zones 4-12', 4, 12, 210);
EXECUTE insert_product(92, 'Zones 5-13', 5, 13, 210);
EXECUTE insert_product(93, 'Zones 6-14', 6, 14, 210);
EXECUTE insert_product(94, 'Zones 7-15', 7, 15, 210);
EXECUTE insert_product(95, 'Zones 2-11', 2, 11, 210);
EXECUTE insert_product(96, 'Zones 3-12', 3, 12, 210);
EXECUTE insert_product(97, 'Zones 4-13', 4, 13, 210);
EXECUTE insert_product(98, 'Zones 5-14', 5, 14, 210);
EXECUTE insert_product(99, 'Zones 6-15', 6, 15, 210);
EXECUTE insert_product(100, 'Zones 2-12', 2, 12, 210);
EXECUTE insert_product(101, 'Zones 3-13', 3, 13, 210);
EXECUTE insert_product(102, 'Zones 4-14', 4, 14, 210);
EXECUTE insert_product(103, 'Zones 5-15', 5, 15, 210);
EXECUTE insert_product(104, 'Zones 2-13', 2, 13, 240);
EXECUTE insert_product(105, 'Zones 3-14', 3, 14, 240);
EXECUTE insert_product(106, 'Zones 4-15', 4, 15, 240);
EXECUTE insert_product(107, 'Zones 2-14', 2, 14, 240);
EXECUTE insert_product(108, 'Zones 3-15', 3, 15, 240);
EXECUTE insert_product(109, 'Zones 2-15', 2, 15, 240);

-- product_fares.sql
PREPARE insert_product_fare(int, int, int, int) AS INSERT INTO "static"."ProductFares" VALUES ($1, $2, $3, $4);
EXECUTE insert_product_fare(1, 0, 0, 530);
EXECUTE insert_product_fare(2, 0, 0, 900);
EXECUTE insert_product_fare(4, 0, 0, 1060);
EXECUTE insert_product_fare(5, 0, 0, 330);
EXECUTE insert_product_fare(6, 0, 0, 280);
EXECUTE insert_product_fare(7, 0, 0, 280);
EXECUTE insert_product_fare(8, 0, 0, 280);
EXECUTE insert_product_fare(9, 0, 0, 280);
EXECUTE insert_product_fare(10, 0, 0, 280);
EXECUTE insert_product_fare(11, 0, 0, 280);
EXECUTE insert_product_fare(12, 0, 0, 280);
EXECUTE insert_product_fare(13, 0, 0, 280);
EXECUTE insert_product_fare(14, 0, 0, 280);
EXECUTE insert_product_fare(15, 0, 0, 280);
EXECUTE insert_product_fare(16, 0, 0, 280);
EXECUTE insert_product_fare(17, 0, 0, 280);
EXECUTE insert_product_fare(18, 0, 0, 280);
EXECUTE insert_product_fare(19, 0, 0, 380);
EXECUTE insert_product_fare(20, 0, 0, 380);
EXECUTE insert_product_fare(21, 0, 0, 380);
EXECUTE insert_product_fare(22, 0, 0, 380);
EXECUTE insert_product_fare(23, 0, 0, 380);
EXECUTE insert_product_fare(24, 0, 0, 380);
EXECUTE insert_product_fare(25, 0, 0, 380);
EXECUTE insert_product_fare(26, 0, 0, 380);
EXECUTE insert_product_fare(27, 0, 0, 380);
EXECUTE insert_product_fare(28, 0, 0, 380);
EXECUTE insert_product_fare(29, 0, 0, 380);
EXECUTE insert_product_fare(30, 0, 0, 380);
EXECUTE insert_product_fare(31, 0, 0, 380);
EXECUTE insert_product_fare(32, 0, 0, 420);
EXECUTE insert_product_fare(33, 0, 0, 420);
EXECUTE insert_product_fare(34, 0, 0, 420);
EXECUTE insert_product_fare(35, 0, 0, 420);
EXECUTE insert_product_fare(36, 0, 0, 420);
EXECUTE insert_product_fare(37, 0, 0, 420);
EXECUTE insert_product_fare(38, 0, 0, 420);
EXECUTE insert_product_fare(39, 0, 0, 420);
EXECUTE insert_product_fare(40, 0, 0, 420);
EXECUTE insert_product_fare(41, 0, 0, 420);
EXECUTE insert_product_fare(42, 0, 0, 420);
EXECUTE insert_product_fare(43, 0, 0, 420);
EXECUTE insert_product_fare(44, 0, 0, 520);
EXECUTE insert_product_fare(45, 0, 0, 520);
EXECUTE insert_product_fare(46, 0, 0, 520);
EXECUTE insert_product_fare(47, 0, 0, 520);
EXECUTE insert_product_fare(48, 0, 0, 520);
EXECUTE insert_product_fare(49, 0, 0, 520);
EXECUTE insert_product_fare(50, 0, 0, 520);
EXECUTE insert_product_fare(51, 0, 0, 520);
EXECUTE insert_product_fare(52, 0, 0, 520);
EXECUTE insert_product_fare(53, 0, 0, 520);
EXECUTE insert_product_fare(54, 0, 0, 520);
EXECUTE insert_product_fare(55, 0, 0, 600);
EXECUTE insert_product_fare(56, 0, 0, 600);
EXECUTE insert_product_fare(57, 0, 0, 600);
EXECUTE insert_product_fare(58, 0, 0, 600);
EXECUTE insert_product_fare(59, 0, 0, 600);
EXECUTE insert_product_fare(60, 0, 0, 600);
EXECUTE insert_product_fare(61, 0, 0, 600);
EXECUTE insert_product_fare(62, 0, 0, 600);
EXECUTE insert_product_fare(63, 0, 0, 600);
EXECUTE insert_product_fare(64, 0, 0, 600);
EXECUTE insert_product_fare(65, 0, 0, 740);
EXECUTE insert_product_fare(66, 0, 0, 740);
EXECUTE insert_product_fare(67, 0, 0, 740);
EXECUTE insert_product_fare(68, 0, 0, 740);
EXECUTE insert_product_fare(69, 0, 0, 740);
EXECUTE insert_product_fare(70, 0, 0, 740);
EXECUTE insert_product_fare(71, 0, 0, 740);
EXECUTE insert_product_fare(72, 0, 0, 740);
EXECUTE insert_product_fare(73, 0, 0, 740);
EXECUTE insert_product_fare(74, 0, 0, 900);
EXECUTE insert_product_fare(75, 0, 0, 900);
EXECUTE insert_product_fare(76, 0, 0, 900);
EXECUTE insert_product_fare(77, 0, 0, 900);
EXECUTE insert_product_fare(78, 0, 0, 900);
EXECUTE insert_product_fare(79, 0, 0, 900);
EXECUTE insert_product_fare(80, 0, 0, 900);
EXECUTE insert_product_fare(81, 0, 0, 900);
EXECUTE insert_product_fare(82, 0, 0, 1060);
EXECUTE insert_product_fare(83, 0, 0, 1060);
EXECUTE insert_product_fare(84, 0, 0, 1060);
EXECUTE insert_product_fare(85, 0, 0, 1060);
EXECUTE insert_product_fare(86, 0, 0, 1060);
EXECUTE insert_product_fare(87, 0, 0, 1060);
EXECUTE insert_product_fare(88, 0, 0, 1060);
EXECUTE insert_product_fare(89, 0, 0, 1060);
EXECUTE insert_product_fare(90, 0, 0, 1060);
EXECUTE insert_product_fare(91, 0, 0, 1060);
EXECUTE insert_product_fare(92, 0, 0, 1060);
EXECUTE insert_product_fare(93, 0, 0, 1060);
EXECUTE insert_product_fare(94, 0, 0, 1060);
EXECUTE insert_product_fare(95, 0, 0, 1060);
EXECUTE insert_product_fare(96, 0, 0, 1060);
EXECUTE insert_product_fare(97, 0, 0, 1060);
EXECUTE insert_product_fare(98, 0, 0, 1060);
EXECUTE insert_product_fare(99, 0, 0, 1060);
EXECUTE insert_product_fare(100, 0, 0, 1060);
EXECUTE insert_product_fare(101, 0, 0, 1060);
EXECUTE insert_product_fare(102, 0, 0, 1060);
EXECUTE insert_product_fare(103, 0, 0, 1060);
EXECUTE insert_product_fare(104, 0, 0, 1060);
EXECUTE insert_product_fare(105, 0, 0, 1060);
EXECUTE insert_product_fare(106, 0, 0, 1060);
EXECUTE insert_product_fare(107, 0, 0, 1060);
EXECUTE insert_product_fare(108, 0, 0, 1060);
EXECUTE insert_product_fare(109, 0, 0, 1060);
EXECUTE insert_product_fare(1, 1, 0, 265);
EXECUTE insert_product_fare(2, 1, 0, 450);
EXECUTE insert_product_fare(4, 1, 0, 530);
EXECUTE insert_product_fare(5, 1, 0, 165);
EXECUTE insert_product_fare(6, 1, 0, 140);
EXECUTE insert_product_fare(7, 1, 0, 140);
EXECUTE insert_product_fare(8, 1, 0, 140);
EXECUTE insert_product_fare(9, 1, 0, 140);
EXECUTE insert_product_fare(10, 1, 0, 140);
EXECUTE insert_product_fare(11, 1, 0, 140);
EXECUTE insert_product_fare(12, 1, 0, 140);
EXECUTE insert_product_fare(13, 1, 0, 140);
EXECUTE insert_product_fare(14, 1, 0, 140);
EXECUTE insert_product_fare(15, 1, 0, 140);
EXECUTE insert_product_fare(16, 1, 0, 140);
EXECUTE insert_product_fare(17, 1, 0, 140);
EXECUTE insert_product_fare(18, 1, 0, 140);
EXECUTE insert_product_fare(19, 1, 0, 190);
EXECUTE insert_product_fare(20, 1, 0, 190);
EXECUTE insert_product_fare(21, 1, 0, 190);
EXECUTE insert_product_fare(22, 1, 0, 190);
EXECUTE insert_product_fare(23, 1, 0, 190);
EXECUTE insert_product_fare(24, 1, 0, 190);
EXECUTE insert_product_fare(25, 1, 0, 190);
EXECUTE insert_product_fare(26, 1, 0, 190);
EXECUTE insert_product_fare(27, 1, 0, 190);
EXECUTE insert_product_fare(28, 1, 0, 190);
EXECUTE insert_product_fare(29, 1, 0, 190);
EXECUTE insert_product_fare(30, 1, 0, 190);
EXECUTE insert_product_fare(31, 1, 0, 190);
EXECUTE insert_product_fare(32, 1, 0, 210);
EXECUTE insert_product_fare(33, 1, 0, 210);
EXECUTE insert_product_fare(34, 1, 0, 210);
EXECUTE insert_product_fare(35, 1, 0, 210);
EXECUTE insert_product_fare(36, 1, 0, 210);
EXECUTE insert_product_fare(37, 1, 0, 210);
EXECUTE insert_product_fare(38, 1, 0, 210);
EXECUTE insert_product_fare(39, 1, 0, 210);
EXECUTE insert_product_fare(40, 1, 0, 210);
EXECUTE insert_product_fare(41, 1, 0, 210);
EXECUTE insert_product_fare(42, 1, 0, 210);
EXECUTE insert_product_fare(43, 1, 0, 210);
EXECUTE insert_product_fare(44, 1, 0, 260);
EXECUTE insert_product_fare(45, 1, 0, 260);
EXECUTE insert_product_fare(46, 1, 0, 260);
EXECUTE insert_product_fare(47, 1, 0, 260);
EXECUTE insert_product_fare(48, 1, 0, 260);
EXECUTE insert_product_fare(49, 1, 0, 260);
EXECUTE insert_product_fare(50, 1, 0, 260);
EXECUTE insert_product_fare(51, 1, 0, 260);
EXECUTE insert_product_fare(52, 1, 0, 260);
EXECUTE insert_product_fare(53, 1, 0, 260);
EXECUTE insert_product_fare(54, 1, 0, 260);
EXECUTE insert_product_fare(55, 1, 0, 300);
EXECUTE insert_product_fare(56, 1, 0, 300);
EXECUTE insert_product_fare(57, 1, 0, 300);
EXECUTE insert_product_fare(58, 1, 0, 300);
EXECUTE insert_product_fare(59, 1, 0, 300);
EXECUTE insert_product_fare(60, 1, 0, 300);
EXECUTE insert_product_fare(61, 1, 0, 300);
EXECUTE insert_product_fare(62, 1, 0, 300);
EXECUTE insert_product_fare(63, 1, 0, 300);
EXECUTE insert_product_fare(64, 1, 0, 300);
EXECUTE insert_product_fare(65, 1, 0, 370);
EXECUTE insert_product_fare(66, 1, 0, 370);
EXECUTE insert_product_fare(67, 1, 0, 370);
EXECUTE insert_product_fare(68, 1, 0, 370);
EXECUTE insert_product_fare(69, 1, 0, 370);
EXECUTE insert_product_fare(70, 1, 0, 370);
EXECUTE insert_product_fare(71, 1, 0, 370);
EXECUTE insert_product_fare(72, 1, 0, 370);
EXECUTE insert_product_fare(73, 1, 0, 370);
EXECUTE insert_product_fare(74, 1, 0, 450);
EXECUTE insert_product_fare(75, 1, 0, 450);
EXECUTE insert_product_fare(76, 1, 0, 450);
EXECUTE insert_product_fare(77, 1, 0, 450);
EXECUTE insert_product_fare(78, 1, 0, 450);
EXECUTE insert_product_fare(79, 1, 0, 450);
EXECUTE insert_product_fare(80, 1, 0, 450);
EXECUTE insert_product_fare(81, 1, 0, 450);
EXECUTE insert_product_fare(82, 1, 0, 530);
EXECUTE insert_product_fare(83, 1, 0, 530);
EXECUTE insert_product_fare(84, 1, 0, 530);
EXECUTE insert_product_fare(85, 1, 0, 530);
EXECUTE insert_product_fare(86, 1, 0, 530);
EXECUTE insert_product_fare(87, 1, 0, 530);
EXECUTE insert_product_fare(88, 1, 0, 530);
EXECUTE insert_product_fare(89, 1, 0, 530);
EXECUTE insert_product_fare(90, 1, 0, 530);
EXECUTE insert_product_fare(91, 1, 0, 530);
EXECUTE insert_product_fare(92, 1, 0, 530);
EXECUTE insert_product_fare(93, 1, 0, 530);
EXECUTE insert_product_fare(94, 1, 0, 530);
EXECUTE insert_product_fare(95, 1, 0, 530);
EXECUTE insert_product_fare(96, 1, 0, 530);
EXECUTE insert_product_fare(97, 1, 0, 530);
EXECUTE insert_product_fare(98, 1, 0, 530);
EXECUTE insert_product_fare(99, 1, 0, 530);
EXECUTE insert_product_fare(100, 1, 0, 530);
EXECUTE insert_product_fare(101, 1, 0, 530);
EXECUTE insert_product_fare(102, 1, 0, 530);
EXECUTE insert_product_fare(103, 1, 0, 530);
EXECUTE insert_product_fare(104, 1, 0, 530);
EXECUTE insert_product_fare(105, 1, 0, 530);
EXECUTE insert_product_fare(106, 1, 0, 530);
EXECUTE insert_product_fare(107, 1, 0, 530);
EXECUTE insert_product_fare(108, 1, 0, 530);
EXECUTE insert_product_fare(109, 1, 0, 530);
EXECUTE insert_product_fare(1, 2, 0, 265);
EXECUTE insert_product_fare(2, 2, 0, 450);
EXECUTE insert_product_fare(4, 2, 0, 530);
EXECUTE insert_product_fare(5, 2, 0, 165);
EXECUTE insert_product_fare(6, 2, 0, 140);
EXECUTE insert_product_fare(7, 2, 0, 140);
EXECUTE insert_product_fare(8, 2, 0, 140);
EXECUTE insert_product_fare(9, 2, 0, 140);
EXECUTE insert_product_fare(10, 2, 0, 140);
EXECUTE insert_product_fare(11, 2, 0, 140);
EXECUTE insert_product_fare(12, 2, 0, 140);
EXECUTE insert_product_fare(13, 2, 0, 140);
EXECUTE insert_product_fare(14, 2, 0, 140);
EXECUTE insert_product_fare(15, 2, 0, 140);
EXECUTE insert_product_fare(16, 2, 0, 140);
EXECUTE insert_product_fare(17, 2, 0, 140);
EXECUTE insert_product_fare(18, 2, 0, 140);
EXECUTE insert_product_fare(19, 2, 0, 190);
EXECUTE insert_product_fare(20, 2, 0, 190);
EXECUTE insert_product_fare(21, 2, 0, 190);
EXECUTE insert_product_fare(22, 2, 0, 190);
EXECUTE insert_product_fare(23, 2, 0, 190);
EXECUTE insert_product_fare(24, 2, 0, 190);
EXECUTE insert_product_fare(25, 2, 0, 190);
EXECUTE insert_product_fare(26, 2, 0, 190);
EXECUTE insert_product_fare(27, 2, 0, 190);
EXECUTE insert_product_fare(28, 2, 0, 190);
EXECUTE insert_product_fare(29, 2, 0, 190);
EXECUTE insert_product_fare(30, 2, 0, 190);
EXECUTE insert_product_fare(31, 2, 0, 190);
EXECUTE insert_product_fare(32, 2, 0, 210);
EXECUTE insert_product_fare(33, 2, 0, 210);
EXECUTE insert_product_fare(34, 2, 0, 210);
EXECUTE insert_product_fare(35, 2, 0, 210);
EXECUTE insert_product_fare(36, 2, 0, 210);
EXECUTE insert_product_fare(37, 2, 0, 210);
EXECUTE insert_product_fare(38, 2, 0, 210);
EXECUTE insert_product_fare(39, 2, 0, 210);
EXECUTE insert_product_fare(40, 2, 0, 210);
EXECUTE insert_product_fare(41, 2, 0, 210);
EXECUTE insert_product_fare(42, 2, 0, 210);
EXECUTE insert_product_fare(43, 2, 0, 210);
EXECUTE insert_product_fare(44, 2, 0, 260);
EXECUTE insert_product_fare(45, 2, 0, 260);
EXECUTE insert_product_fare(46, 2, 0, 260);
EXECUTE insert_product_fare(47, 2, 0, 260);
EXECUTE insert_product_fare(48, 2, 0, 260);
EXECUTE insert_product_fare(49, 2, 0, 260);
EXECUTE insert_product_fare(50, 2, 0, 260);
EXECUTE insert_product_fare(51, 2, 0, 260);
EXECUTE insert_product_fare(52, 2, 0, 260);
EXECUTE insert_product_fare(53, 2, 0, 260);
EXECUTE insert_product_fare(54, 2, 0, 260);
EXECUTE insert_product_fare(55, 2, 0, 300);
EXECUTE insert_product_fare(56, 2, 0, 300);
EXECUTE insert_product_fare(57, 2, 0, 300);
EXECUTE insert_product_fare(58, 2, 0, 300);
EXECUTE insert_product_fare(59, 2, 0, 300);
EXECUTE insert_product_fare(60, 2, 0, 300);
EXECUTE insert_product_fare(61, 2, 0, 300);
EXECUTE insert_product_fare(62, 2, 0, 300);
EXECUTE insert_product_fare(63, 2, 0, 300);
EXECUTE insert_product_fare(64, 2, 0, 300);
EXECUTE insert_product_fare(65, 2, 0, 370);
EXECUTE insert_product_fare(66, 2, 0, 370);
EXECUTE insert_product_fare(67, 2, 0, 370);
EXECUTE insert_product_fare(68, 2, 0, 370);
EXECUTE insert_product_fare(69, 2, 0, 370);
EXECUTE insert_product_fare(70, 2, 0, 370);
EXECUTE insert_product_fare(71, 2, 0, 370);
EXECUTE insert_product_fare(72, 2, 0, 370);
EXECUTE insert_product_fare(73, 2, 0, 370);
EXECUTE insert_product_fare(74, 2, 0, 450);
EXECUTE insert_product_fare(75, 2, 0, 450);
EXECUTE insert_product_fare(76, 2, 0, 450);
EXECUTE insert_product_fare(77, 2, 0, 450);
EXECUTE insert_product_fare(78, 2, 0, 450);
EXECUTE insert_product_fare(79, 2, 0, 450);
EXECUTE insert_product_fare(80, 2, 0, 450);
EXECUTE insert_product_fare(81, 2, 0, 450);
EXECUTE insert_product_fare(82, 2, 0, 530);
EXECUTE insert_product_fare(83, 2, 0, 530);
EXECUTE insert_product_fare(84, 2, 0, 530);
EXECUTE insert_product_fare(85, 2, 0, 530);
EXECUTE insert_product_fare(86, 2, 0, 530);
EXECUTE insert_product_fare(87, 2, 0, 530);
EXECUTE insert_product_fare(88, 2, 0, 530);
EXECUTE insert_product_fare(89, 2, 0, 530);
EXECUTE insert_product_fare(90, 2, 0, 530);
EXECUTE insert_product_fare(91, 2, 0, 530);
EXECUTE insert_product_fare(92, 2, 0, 530);
EXECUTE insert_product_fare(93, 2, 0, 530);
EXECUTE insert_product_fare(94, 2, 0, 530);
EXECUTE insert_product_fare(95, 2, 0, 530);
EXECUTE insert_product_fare(96, 2, 0, 530);
EXECUTE insert_product_fare(97, 2, 0, 530);
EXECUTE insert_product_fare(98, 2, 0, 530);
EXECUTE insert_product_fare(99, 2, 0, 530);
EXECUTE insert_product_fare(100, 2, 0, 530);
EXECUTE insert_product_fare(101, 2, 0, 530);
EXECUTE insert_product_fare(102, 2, 0, 530);
EXECUTE insert_product_fare(103, 2, 0, 530);
EXECUTE insert_product_fare(104, 2, 0, 530);
EXECUTE insert_product_fare(105, 2, 0, 530);
EXECUTE insert_product_fare(106, 2, 0, 530);
EXECUTE insert_product_fare(107, 2, 0, 530);
EXECUTE insert_product_fare(108, 2, 0, 530);
EXECUTE insert_product_fare(109, 2, 0, 530);
EXECUTE insert_product_fare(1, 3, 0, 265);
EXECUTE insert_product_fare(2, 3, 0, 450);
EXECUTE insert_product_fare(4, 3, 0, 530);
EXECUTE insert_product_fare(5, 3, 0, 165);
EXECUTE insert_product_fare(6, 3, 0, 140);
EXECUTE insert_product_fare(7, 3, 0, 140);
EXECUTE insert_product_fare(8, 3, 0, 140);
EXECUTE insert_product_fare(9, 3, 0, 140);
EXECUTE insert_product_fare(10, 3, 0, 140);
EXECUTE insert_product_fare(11, 3, 0, 140);
EXECUTE insert_product_fare(12, 3, 0, 140);
EXECUTE insert_product_fare(13, 3, 0, 140);
EXECUTE insert_product_fare(14, 3, 0, 140);
EXECUTE insert_product_fare(15, 3, 0, 140);
EXECUTE insert_product_fare(16, 3, 0, 140);
EXECUTE insert_product_fare(17, 3, 0, 140);
EXECUTE insert_product_fare(18, 3, 0, 140);
EXECUTE insert_product_fare(19, 3, 0, 190);
EXECUTE insert_product_fare(20, 3, 0, 190);
EXECUTE insert_product_fare(21, 3, 0, 190);
EXECUTE insert_product_fare(22, 3, 0, 190);
EXECUTE insert_product_fare(23, 3, 0, 190);
EXECUTE insert_product_fare(24, 3, 0, 190);
EXECUTE insert_product_fare(25, 3, 0, 190);
EXECUTE insert_product_fare(26, 3, 0, 190);
EXECUTE insert_product_fare(27, 3, 0, 190);
EXECUTE insert_product_fare(28, 3, 0, 190);
EXECUTE insert_product_fare(29, 3, 0, 190);
EXECUTE insert_product_fare(30, 3, 0, 190);
EXECUTE insert_product_fare(31, 3, 0, 190);
EXECUTE insert_product_fare(32, 3, 0, 210);
EXECUTE insert_product_fare(33, 3, 0, 210);
EXECUTE insert_product_fare(34, 3, 0, 210);
EXECUTE insert_product_fare(35, 3, 0, 210);
EXECUTE insert_product_fare(36, 3, 0, 210);
EXECUTE insert_product_fare(37, 3, 0, 210);
EXECUTE insert_product_fare(38, 3, 0, 210);
EXECUTE insert_product_fare(39, 3, 0, 210);
EXECUTE insert_product_fare(40, 3, 0, 210);
EXECUTE insert_product_fare(41, 3, 0, 210);
EXECUTE insert_product_fare(42, 3, 0, 210);
EXECUTE insert_product_fare(43, 3, 0, 210);
EXECUTE insert_product_fare(44, 3, 0, 260);
EXECUTE insert_product_fare(45, 3, 0, 260);
EXECUTE insert_product_fare(46, 3, 0, 260);
EXECUTE insert_product_fare(47, 3, 0, 260);
EXECUTE insert_product_fare(48, 3, 0, 260);
EXECUTE insert_product_fare(49, 3, 0, 260);
EXECUTE insert_product_fare(50, 3, 0, 260);
EXECUTE insert_product_fare(51, 3, 0, 260);
EXECUTE insert_product_fare(52, 3, 0, 260);
EXECUTE insert_product_fare(53, 3, 0, 260);
EXECUTE insert_product_fare(54, 3, 0, 260);
EXECUTE insert_product_fare(55, 3, 0, 300);
EXECUTE insert_product_fare(56, 3, 0, 300);
EXECUTE insert_product_fare(57, 3, 0, 300);
EXECUTE insert_product_fare(58, 3, 0, 300);
EXECUTE insert_product_fare(59, 3, 0, 300);
EXECUTE insert_product_fare(60, 3, 0, 300);
EXECUTE insert_product_fare(61, 3, 0, 300);
EXECUTE insert_product_fare(62, 3, 0, 300);
EXECUTE insert_product_fare(63, 3, 0, 300);
EXECUTE insert_product_fare(64, 3, 0, 300);
EXECUTE insert_product_fare(65, 3, 0, 370);
EXECUTE insert_product_fare(66, 3, 0, 370);
EXECUTE insert_product_fare(67, 3, 0, 370);
EXECUTE insert_product_fare(68, 3, 0, 370);
EXECUTE insert_product_fare(69, 3, 0, 370);
EXECUTE insert_product_fare(70, 3, 0, 370);
EXECUTE insert_product_fare(71, 3, 0, 370);
EXECUTE insert_product_fare(72, 3, 0, 370);
EXECUTE insert_product_fare(73, 3, 0, 370);
EXECUTE insert_product_fare(74, 3, 0, 450);
EXECUTE insert_product_fare(75, 3, 0, 450);
EXECUTE insert_product_fare(76, 3, 0, 450);
EXECUTE insert_product_fare(77, 3, 0, 450);
EXECUTE insert_product_fare(78, 3, 0, 450);
EXECUTE insert_product_fare(79, 3, 0, 450);
EXECUTE insert_product_fare(80, 3, 0, 450);
EXECUTE insert_product_fare(81, 3, 0, 450);
EXECUTE insert_product_fare(82, 3, 0, 530);
EXECUTE insert_product_fare(83, 3, 0, 530);
EXECUTE insert_product_fare(84, 3, 0, 530);
EXECUTE insert_product_fare(85, 3, 0, 530);
EXECUTE insert_product_fare(86, 3, 0, 530);
EXECUTE insert_product_fare(87, 3, 0, 530);
EXECUTE insert_product_fare(88, 3, 0, 530);
EXECUTE insert_product_fare(89, 3, 0, 530);
EXECUTE insert_product_fare(90, 3, 0, 530);
EXECUTE insert_product_fare(91, 3, 0, 530);
EXECUTE insert_product_fare(92, 3, 0, 530);
EXECUTE insert_product_fare(93, 3, 0, 530);
EXECUTE insert_product_fare(94, 3, 0, 530);
EXECUTE insert_product_fare(95, 3, 0, 530);
EXECUTE insert_product_fare(96, 3, 0, 530);
EXECUTE insert_product_fare(97, 3, 0, 530);
EXECUTE insert_product_fare(98, 3, 0, 530);
EXECUTE insert_product_fare(99, 3, 0, 530);
EXECUTE insert_product_fare(100, 3, 0, 530);
EXECUTE insert_product_fare(101, 3, 0, 530);
EXECUTE insert_product_fare(102, 3, 0, 530);
EXECUTE insert_product_fare(103, 3, 0, 530);
EXECUTE insert_product_fare(104, 3, 0, 530);
EXECUTE insert_product_fare(105, 3, 0, 530);
EXECUTE insert_product_fare(106, 3, 0, 530);
EXECUTE insert_product_fare(107, 3, 0, 530);
EXECUTE insert_product_fare(108, 3, 0, 530);
EXECUTE insert_product_fare(109, 3, 0, 530);
EXECUTE insert_product_fare(1, 4, 0, 265);
EXECUTE insert_product_fare(2, 4, 0, 450);
EXECUTE insert_product_fare(4, 4, 0, 530);
EXECUTE insert_product_fare(5, 4, 0, 165);
EXECUTE insert_product_fare(6, 4, 0, 140);
EXECUTE insert_product_fare(7, 4, 0, 140);
EXECUTE insert_product_fare(8, 4, 0, 140);
EXECUTE insert_product_fare(9, 4, 0, 140);
EXECUTE insert_product_fare(10, 4, 0, 140);
EXECUTE insert_product_fare(11, 4, 0, 140);
EXECUTE insert_product_fare(12, 4, 0, 140);
EXECUTE insert_product_fare(13, 4, 0, 140);
EXECUTE insert_product_fare(14, 4, 0, 140);
EXECUTE insert_product_fare(15, 4, 0, 140);
EXECUTE insert_product_fare(16, 4, 0, 140);
EXECUTE insert_product_fare(17, 4, 0, 140);
EXECUTE insert_product_fare(18, 4, 0, 140);
EXECUTE insert_product_fare(19, 4, 0, 190);
EXECUTE insert_product_fare(20, 4, 0, 190);
EXECUTE insert_product_fare(21, 4, 0, 190);
EXECUTE insert_product_fare(22, 4, 0, 190);
EXECUTE insert_product_fare(23, 4, 0, 190);
EXECUTE insert_product_fare(24, 4, 0, 190);
EXECUTE insert_product_fare(25, 4, 0, 190);
EXECUTE insert_product_fare(26, 4, 0, 190);
EXECUTE insert_product_fare(27, 4, 0, 190);
EXECUTE insert_product_fare(28, 4, 0, 190);
EXECUTE insert_product_fare(29, 4, 0, 190);
EXECUTE insert_product_fare(30, 4, 0, 190);
EXECUTE insert_product_fare(31, 4, 0, 190);
EXECUTE insert_product_fare(32, 4, 0, 210);
EXECUTE insert_product_fare(33, 4, 0, 210);
EXECUTE insert_product_fare(34, 4, 0, 210);
EXECUTE insert_product_fare(35, 4, 0, 210);
EXECUTE insert_product_fare(36, 4, 0, 210);
EXECUTE insert_product_fare(37, 4, 0, 210);
EXECUTE insert_product_fare(38, 4, 0, 210);
EXECUTE insert_product_fare(39, 4, 0, 210);
EXECUTE insert_product_fare(40, 4, 0, 210);
EXECUTE insert_product_fare(41, 4, 0, 210);
EXECUTE insert_product_fare(42, 4, 0, 210);
EXECUTE insert_product_fare(43, 4, 0, 210);
EXECUTE insert_product_fare(44, 4, 0, 260);
EXECUTE insert_product_fare(45, 4, 0, 260);
EXECUTE insert_product_fare(46, 4, 0, 260);
EXECUTE insert_product_fare(47, 4, 0, 260);
EXECUTE insert_product_fare(48, 4, 0, 260);
EXECUTE insert_product_fare(49, 4, 0, 260);
EXECUTE insert_product_fare(50, 4, 0, 260);
EXECUTE insert_product_fare(51, 4, 0, 260);
EXECUTE insert_product_fare(52, 4, 0, 260);
EXECUTE insert_product_fare(53, 4, 0, 260);
EXECUTE insert_product_fare(54, 4, 0, 260);
EXECUTE insert_product_fare(55, 4, 0, 300);
EXECUTE insert_product_fare(56, 4, 0, 300);
EXECUTE insert_product_fare(57, 4, 0, 300);
EXECUTE insert_product_fare(58, 4, 0, 300);
EXECUTE insert_product_fare(59, 4, 0, 300);
EXECUTE insert_product_fare(60, 4, 0, 300);
EXECUTE insert_product_fare(61, 4, 0, 300);
EXECUTE insert_product_fare(62, 4, 0, 300);
EXECUTE insert_product_fare(63, 4, 0, 300);
EXECUTE insert_product_fare(64, 4, 0, 300);
EXECUTE insert_product_fare(65, 4, 0, 370);
EXECUTE insert_product_fare(66, 4, 0, 370);
EXECUTE insert_product_fare(67, 4, 0, 370);
EXECUTE insert_product_fare(68, 4, 0, 370);
EXECUTE insert_product_fare(69, 4, 0, 370);
EXECUTE insert_product_fare(70, 4, 0, 370);
EXECUTE insert_product_fare(71, 4, 0, 370);
EXECUTE insert_product_fare(72, 4, 0, 370);
EXECUTE insert_product_fare(73, 4, 0, 370);
EXECUTE insert_product_fare(74, 4, 0, 450);
EXECUTE insert_product_fare(75, 4, 0, 450);
EXECUTE insert_product_fare(76, 4, 0, 450);
EXECUTE insert_product_fare(77, 4, 0, 450);
EXECUTE insert_product_fare(78, 4, 0, 450);
EXECUTE insert_product_fare(79, 4, 0, 450);
EXECUTE insert_product_fare(80, 4, 0, 450);
EXECUTE insert_product_fare(81, 4, 0, 450);
EXECUTE insert_product_fare(82, 4, 0, 530);
EXECUTE insert_product_fare(83, 4, 0, 530);
EXECUTE insert_product_fare(84, 4, 0, 530);
EXECUTE insert_product_fare(85, 4, 0, 530);
EXECUTE insert_product_fare(86, 4, 0, 530);
EXECUTE insert_product_fare(87, 4, 0, 530);
EXECUTE insert_product_fare(88, 4, 0, 530);
EXECUTE insert_product_fare(89, 4, 0, 530);
EXECUTE insert_product_fare(90, 4, 0, 530);
EXECUTE insert_product_fare(91, 4, 0, 530);
EXECUTE insert_product_fare(92, 4, 0, 530);
EXECUTE insert_product_fare(93, 4, 0, 530);
EXECUTE insert_product_fare(94, 4, 0, 530);
EXECUTE insert_product_fare(95, 4, 0, 530);
EXECUTE insert_product_fare(96, 4, 0, 530);
EXECUTE insert_product_fare(97, 4, 0, 530);
EXECUTE insert_product_fare(98, 4, 0, 530);
EXECUTE insert_product_fare(99, 4, 0, 530);
EXECUTE insert_product_fare(100, 4, 0, 530);
EXECUTE insert_product_fare(101, 4, 0, 530);
EXECUTE insert_product_fare(102, 4, 0, 530);
EXECUTE insert_product_fare(103, 4, 0, 530);
EXECUTE insert_product_fare(104, 4, 0, 530);
EXECUTE insert_product_fare(105, 4, 0, 530);
EXECUTE insert_product_fare(106, 4, 0, 530);
EXECUTE insert_product_fare(107, 4, 0, 530);
EXECUTE insert_product_fare(108, 4, 0, 530);
EXECUTE insert_product_fare(109, 4, 0, 530);
EXECUTE insert_product_fare(1, 5, 0, 265);
EXECUTE insert_product_fare(2, 5, 0, 450);
EXECUTE insert_product_fare(4, 5, 0, 530);
EXECUTE insert_product_fare(5, 5, 0, 165);
EXECUTE insert_product_fare(6, 5, 0, 140);
EXECUTE insert_product_fare(7, 5, 0, 140);
EXECUTE insert_product_fare(8, 5, 0, 140);
EXECUTE insert_product_fare(9, 5, 0, 140);
EXECUTE insert_product_fare(10, 5, 0, 140);
EXECUTE insert_product_fare(11, 5, 0, 140);
EXECUTE insert_product_fare(12, 5, 0, 140);
EXECUTE insert_product_fare(13, 5, 0, 140);
EXECUTE insert_product_fare(14, 5, 0, 140);
EXECUTE insert_product_fare(15, 5, 0, 140);
EXECUTE insert_product_fare(16, 5, 0, 140);
EXECUTE insert_product_fare(17, 5, 0, 140);
EXECUTE insert_product_fare(18, 5, 0, 140);
EXECUTE insert_product_fare(19, 5, 0, 190);
EXECUTE insert_product_fare(20, 5, 0, 190);
EXECUTE insert_product_fare(21, 5, 0, 190);
EXECUTE insert_product_fare(22, 5, 0, 190);
EXECUTE insert_product_fare(23, 5, 0, 190);
EXECUTE insert_product_fare(24, 5, 0, 190);
EXECUTE insert_product_fare(25, 5, 0, 190);
EXECUTE insert_product_fare(26, 5, 0, 190);
EXECUTE insert_product_fare(27, 5, 0, 190);
EXECUTE insert_product_fare(28, 5, 0, 190);
EXECUTE insert_product_fare(29, 5, 0, 190);
EXECUTE insert_product_fare(30, 5, 0, 190);
EXECUTE insert_product_fare(31, 5, 0, 190);
EXECUTE insert_product_fare(32, 5, 0, 210);
EXECUTE insert_product_fare(33, 5, 0, 210);
EXECUTE insert_product_fare(34, 5, 0, 210);
EXECUTE insert_product_fare(35, 5, 0, 210);
EXECUTE insert_product_fare(36, 5, 0, 210);
EXECUTE insert_product_fare(37, 5, 0, 210);
EXECUTE insert_product_fare(38, 5, 0, 210);
EXECUTE insert_product_fare(39, 5, 0, 210);
EXECUTE insert_product_fare(40, 5, 0, 210);
EXECUTE insert_product_fare(41, 5, 0, 210);
EXECUTE insert_product_fare(42, 5, 0, 210);
EXECUTE insert_product_fare(43, 5, 0, 210);
EXECUTE insert_product_fare(44, 5, 0, 260);
EXECUTE insert_product_fare(45, 5, 0, 260);
EXECUTE insert_product_fare(46, 5, 0, 260);
EXECUTE insert_product_fare(47, 5, 0, 260);
EXECUTE insert_product_fare(48, 5, 0, 260);
EXECUTE insert_product_fare(49, 5, 0, 260);
EXECUTE insert_product_fare(50, 5, 0, 260);
EXECUTE insert_product_fare(51, 5, 0, 260);
EXECUTE insert_product_fare(52, 5, 0, 260);
EXECUTE insert_product_fare(53, 5, 0, 260);
EXECUTE insert_product_fare(54, 5, 0, 260);
EXECUTE insert_product_fare(55, 5, 0, 300);
EXECUTE insert_product_fare(56, 5, 0, 300);
EXECUTE insert_product_fare(57, 5, 0, 300);
EXECUTE insert_product_fare(58, 5, 0, 300);
EXECUTE insert_product_fare(59, 5, 0, 300);
EXECUTE insert_product_fare(60, 5, 0, 300);
EXECUTE insert_product_fare(61, 5, 0, 300);
EXECUTE insert_product_fare(62, 5, 0, 300);
EXECUTE insert_product_fare(63, 5, 0, 300);
EXECUTE insert_product_fare(64, 5, 0, 300);
EXECUTE insert_product_fare(65, 5, 0, 370);
EXECUTE insert_product_fare(66, 5, 0, 370);
EXECUTE insert_product_fare(67, 5, 0, 370);
EXECUTE insert_product_fare(68, 5, 0, 370);
EXECUTE insert_product_fare(69, 5, 0, 370);
EXECUTE insert_product_fare(70, 5, 0, 370);
EXECUTE insert_product_fare(71, 5, 0, 370);
EXECUTE insert_product_fare(72, 5, 0, 370);
EXECUTE insert_product_fare(73, 5, 0, 370);
EXECUTE insert_product_fare(74, 5, 0, 450);
EXECUTE insert_product_fare(75, 5, 0, 450);
EXECUTE insert_product_fare(76, 5, 0, 450);
EXECUTE insert_product_fare(77, 5, 0, 450);
EXECUTE insert_product_fare(78, 5, 0, 450);
EXECUTE insert_product_fare(79, 5, 0, 450);
EXECUTE insert_product_fare(80, 5, 0, 450);
EXECUTE insert_product_fare(81, 5, 0, 450);
EXECUTE insert_product_fare(82, 5, 0, 530);
EXECUTE insert_product_fare(83, 5, 0, 530);
EXECUTE insert_product_fare(84, 5, 0, 530);
EXECUTE insert_product_fare(85, 5, 0, 530);
EXECUTE insert_product_fare(86, 5, 0, 530);
EXECUTE insert_product_fare(87, 5, 0, 530);
EXECUTE insert_product_fare(88, 5, 0, 530);
EXECUTE insert_product_fare(89, 5, 0, 530);
EXECUTE insert_product_fare(90, 5, 0, 530);
EXECUTE insert_product_fare(91, 5, 0, 530);
EXECUTE insert_product_fare(92, 5, 0, 530);
EXECUTE insert_product_fare(93, 5, 0, 530);
EXECUTE insert_product_fare(94, 5, 0, 530);
EXECUTE insert_product_fare(95, 5, 0, 530);
EXECUTE insert_product_fare(96, 5, 0, 530);
EXECUTE insert_product_fare(97, 5, 0, 530);
EXECUTE insert_product_fare(98, 5, 0, 530);
EXECUTE insert_product_fare(99, 5, 0, 530);
EXECUTE insert_product_fare(100, 5, 0, 530);
EXECUTE insert_product_fare(101, 5, 0, 530);
EXECUTE insert_product_fare(102, 5, 0, 530);
EXECUTE insert_product_fare(103, 5, 0, 530);
EXECUTE insert_product_fare(104, 5, 0, 530);
EXECUTE insert_product_fare(105, 5, 0, 530);
EXECUTE insert_product_fare(106, 5, 0, 530);
EXECUTE insert_product_fare(107, 5, 0, 530);
EXECUTE insert_product_fare(108, 5, 0, 530);
EXECUTE insert_product_fare(109, 5, 0, 530);
EXECUTE insert_product_fare(1, 6, 0, 265);
EXECUTE insert_product_fare(2, 6, 0, 450);
EXECUTE insert_product_fare(4, 6, 0, 530);
EXECUTE insert_product_fare(5, 6, 0, 165);
EXECUTE insert_product_fare(6, 6, 0, 140);
EXECUTE insert_product_fare(7, 6, 0, 140);
EXECUTE insert_product_fare(8, 6, 0, 140);
EXECUTE insert_product_fare(9, 6, 0, 140);
EXECUTE insert_product_fare(10, 6, 0, 140);
EXECUTE insert_product_fare(11, 6, 0, 140);
EXECUTE insert_product_fare(12, 6, 0, 140);
EXECUTE insert_product_fare(13, 6, 0, 140);
EXECUTE insert_product_fare(14, 6, 0, 140);
EXECUTE insert_product_fare(15, 6, 0, 140);
EXECUTE insert_product_fare(16, 6, 0, 140);
EXECUTE insert_product_fare(17, 6, 0, 140);
EXECUTE insert_product_fare(18, 6, 0, 140);
EXECUTE insert_product_fare(19, 6, 0, 190);
EXECUTE insert_product_fare(20, 6, 0, 190);
EXECUTE insert_product_fare(21, 6, 0, 190);
EXECUTE insert_product_fare(22, 6, 0, 190);
EXECUTE insert_product_fare(23, 6, 0, 190);
EXECUTE insert_product_fare(24, 6, 0, 190);
EXECUTE insert_product_fare(25, 6, 0, 190);
EXECUTE insert_product_fare(26, 6, 0, 190);
EXECUTE insert_product_fare(27, 6, 0, 190);
EXECUTE insert_product_fare(28, 6, 0, 190);
EXECUTE insert_product_fare(29, 6, 0, 190);
EXECUTE insert_product_fare(30, 6, 0, 190);
EXECUTE insert_product_fare(31, 6, 0, 190);
EXECUTE insert_product_fare(32, 6, 0, 210);
EXECUTE insert_product_fare(33, 6, 0, 210);
EXECUTE insert_product_fare(34, 6, 0, 210);
EXECUTE insert_product_fare(35, 6, 0, 210);
EXECUTE insert_product_fare(36, 6, 0, 210);
EXECUTE insert_product_fare(37, 6, 0, 210);
EXECUTE insert_product_fare(38, 6, 0, 210);
EXECUTE insert_product_fare(39, 6, 0, 210);
EXECUTE insert_product_fare(40, 6, 0, 210);
EXECUTE insert_product_fare(41, 6, 0, 210);
EXECUTE insert_product_fare(42, 6, 0, 210);
EXECUTE insert_product_fare(43, 6, 0, 210);
EXECUTE insert_product_fare(44, 6, 0, 260);
EXECUTE insert_product_fare(45, 6, 0, 260);
EXECUTE insert_product_fare(46, 6, 0, 260);
EXECUTE insert_product_fare(47, 6, 0, 260);
EXECUTE insert_product_fare(48, 6, 0, 260);
EXECUTE insert_product_fare(49, 6, 0, 260);
EXECUTE insert_product_fare(50, 6, 0, 260);
EXECUTE insert_product_fare(51, 6, 0, 260);
EXECUTE insert_product_fare(52, 6, 0, 260);
EXECUTE insert_product_fare(53, 6, 0, 260);
EXECUTE insert_product_fare(54, 6, 0, 260);
EXECUTE insert_product_fare(55, 6, 0, 300);
EXECUTE insert_product_fare(56, 6, 0, 300);
EXECUTE insert_product_fare(57, 6, 0, 300);
EXECUTE insert_product_fare(58, 6, 0, 300);
EXECUTE insert_product_fare(59, 6, 0, 300);
EXECUTE insert_product_fare(60, 6, 0, 300);
EXECUTE insert_product_fare(61, 6, 0, 300);
EXECUTE insert_product_fare(62, 6, 0, 300);
EXECUTE insert_product_fare(63, 6, 0, 300);
EXECUTE insert_product_fare(64, 6, 0, 300);
EXECUTE insert_product_fare(65, 6, 0, 370);
EXECUTE insert_product_fare(66, 6, 0, 370);
EXECUTE insert_product_fare(67, 6, 0, 370);
EXECUTE insert_product_fare(68, 6, 0, 370);
EXECUTE insert_product_fare(69, 6, 0, 370);
EXECUTE insert_product_fare(70, 6, 0, 370);
EXECUTE insert_product_fare(71, 6, 0, 370);
EXECUTE insert_product_fare(72, 6, 0, 370);
EXECUTE insert_product_fare(73, 6, 0, 370);
EXECUTE insert_product_fare(74, 6, 0, 450);
EXECUTE insert_product_fare(75, 6, 0, 450);
EXECUTE insert_product_fare(76, 6, 0, 450);
EXECUTE insert_product_fare(77, 6, 0, 450);
EXECUTE insert_product_fare(78, 6, 0, 450);
EXECUTE insert_product_fare(79, 6, 0, 450);
EXECUTE insert_product_fare(80, 6, 0, 450);
EXECUTE insert_product_fare(81, 6, 0, 450);
EXECUTE insert_product_fare(82, 6, 0, 530);
EXECUTE insert_product_fare(83, 6, 0, 530);
EXECUTE insert_product_fare(84, 6, 0, 530);
EXECUTE insert_product_fare(85, 6, 0, 530);
EXECUTE insert_product_fare(86, 6, 0, 530);
EXECUTE insert_product_fare(87, 6, 0, 530);
EXECUTE insert_product_fare(88, 6, 0, 530);
EXECUTE insert_product_fare(89, 6, 0, 530);
EXECUTE insert_product_fare(90, 6, 0, 530);
EXECUTE insert_product_fare(91, 6, 0, 530);
EXECUTE insert_product_fare(92, 6, 0, 530);
EXECUTE insert_product_fare(93, 6, 0, 530);
EXECUTE insert_product_fare(94, 6, 0, 530);
EXECUTE insert_product_fare(95, 6, 0, 530);
EXECUTE insert_product_fare(96, 6, 0, 530);
EXECUTE insert_product_fare(97, 6, 0, 530);
EXECUTE insert_product_fare(98, 6, 0, 530);
EXECUTE insert_product_fare(99, 6, 0, 530);
EXECUTE insert_product_fare(100, 6, 0, 530);
EXECUTE insert_product_fare(101, 6, 0, 530);
EXECUTE insert_product_fare(102, 6, 0, 530);
EXECUTE insert_product_fare(103, 6, 0, 530);
EXECUTE insert_product_fare(104, 6, 0, 530);
EXECUTE insert_product_fare(105, 6, 0, 530);
EXECUTE insert_product_fare(106, 6, 0, 530);
EXECUTE insert_product_fare(107, 6, 0, 530);
EXECUTE insert_product_fare(108, 6, 0, 530);
EXECUTE insert_product_fare(109, 6, 0, 530);
EXECUTE insert_product_fare(1, 3, 1, 0);
EXECUTE insert_product_fare(5, 3, 1, 0);
EXECUTE insert_product_fare(6, 3, 1, 0);
EXECUTE insert_product_fare(7, 3, 1, 0);
EXECUTE insert_product_fare(8, 3, 1, 0);
EXECUTE insert_product_fare(9, 3, 1, 0);
EXECUTE insert_product_fare(10, 3, 1, 0);
EXECUTE insert_product_fare(11, 3, 1, 0);
EXECUTE insert_product_fare(12, 3, 1, 0);
EXECUTE insert_product_fare(13, 3, 1, 0);
EXECUTE insert_product_fare(14, 3, 1, 0);
EXECUTE insert_product_fare(15, 3, 1, 0);
EXECUTE insert_product_fare(16, 3, 1, 0);
EXECUTE insert_product_fare(17, 3, 1, 0);
EXECUTE insert_product_fare(18, 3, 1, 0);
EXECUTE insert_product_fare(19, 3, 1, 0);
EXECUTE insert_product_fare(20, 3, 1, 0);
EXECUTE insert_product_fare(21, 3, 1, 0);
EXECUTE insert_product_fare(22, 3, 1, 0);
EXECUTE insert_product_fare(23, 3, 1, 0);
EXECUTE insert_product_fare(24, 3, 1, 0);
EXECUTE insert_product_fare(25, 3, 1, 0);
EXECUTE insert_product_fare(26, 3, 1, 0);
EXECUTE insert_product_fare(27, 3, 1, 0);
EXECUTE insert_product_fare(28, 3, 1, 0);
EXECUTE insert_product_fare(29, 3, 1, 0);
EXECUTE insert_product_fare(30, 3, 1, 0);
EXECUTE insert_product_fare(31, 3, 1, 0);
EXECUTE insert_product_fare(1, 4, 1, 0);
EXECUTE insert_product_fare(5, 4, 1, 0);
EXECUTE insert_product_fare(6, 4, 1, 0);
EXECUTE insert_product_fare(7, 4, 1, 0);
EXECUTE insert_product_fare(8, 4, 1, 0);
EXECUTE insert_product_fare(9, 4, 1, 0);
EXECUTE insert_product_fare(10, 4, 1, 0);
EXECUTE insert_product_fare(11, 4, 1, 0);
EXECUTE insert_product_fare(12, 4, 1, 0);
EXECUTE insert_product_fare(13, 4, 1, 0);
EXECUTE insert_product_fare(14, 4, 1, 0);
EXECUTE insert_product_fare(15, 4, 1, 0);
EXECUTE insert_product_fare(16, 4, 1, 0);
EXECUTE insert_product_fare(17, 4, 1, 0);
EXECUTE insert_product_fare(18, 4, 1, 0);
EXECUTE insert_product_fare(19, 4, 1, 0);
EXECUTE insert_product_fare(20, 4, 1, 0);
EXECUTE insert_product_fare(21, 4, 1, 0);
EXECUTE insert_product_fare(22, 4, 1, 0);
EXECUTE insert_product_fare(23, 4, 1, 0);
EXECUTE insert_product_fare(24, 4, 1, 0);
EXECUTE insert_product_fare(25, 4, 1, 0);
EXECUTE insert_product_fare(26, 4, 1, 0);
EXECUTE insert_product_fare(27, 4, 1, 0);
EXECUTE insert_product_fare(28, 4, 1, 0);
EXECUTE insert_product_fare(29, 4, 1, 0);
EXECUTE insert_product_fare(30, 4, 1, 0);
EXECUTE insert_product_fare(31, 4, 1, 0);
EXECUTE insert_product_fare(1, 5, 1, 0);
EXECUTE insert_product_fare(5, 5, 1, 0);
EXECUTE insert_product_fare(6, 5, 1, 0);
EXECUTE insert_product_fare(7, 5, 1, 0);
EXECUTE insert_product_fare(8, 5, 1, 0);
EXECUTE insert_product_fare(9, 5, 1, 0);
EXECUTE insert_product_fare(10, 5, 1, 0);
EXECUTE insert_product_fare(11, 5, 1, 0);
EXECUTE insert_product_fare(12, 5, 1, 0);
EXECUTE insert_product_fare(13, 5, 1, 0);
EXECUTE insert_product_fare(14, 5, 1, 0);
EXECUTE insert_product_fare(15, 5, 1, 0);
EXECUTE insert_product_fare(16, 5, 1, 0);
EXECUTE insert_product_fare(17, 5, 1, 0);
EXECUTE insert_product_fare(18, 5, 1, 0);
EXECUTE insert_product_fare(19, 5, 1, 0);
EXECUTE insert_product_fare(20, 5, 1, 0);
EXECUTE insert_product_fare(21, 5, 1, 0);
EXECUTE insert_product_fare(22, 5, 1, 0);
EXECUTE insert_product_fare(23, 5, 1, 0);
EXECUTE insert_product_fare(24, 5, 1, 0);
EXECUTE insert_product_fare(25, 5, 1, 0);
EXECUTE insert_product_fare(26, 5, 1, 0);
EXECUTE insert_product_fare(27, 5, 1, 0);
EXECUTE insert_product_fare(28, 5, 1, 0);
EXECUTE insert_product_fare(29, 5, 1, 0);
EXECUTE insert_product_fare(30, 5, 1, 0);
EXECUTE insert_product_fare(31, 5, 1, 0);

-- modes.sql
-- NOTE: metropolitan train stations served by MTM only!

PREPARE insert_location(varchar(64), int) AS INSERT INTO "static"."Locations" ("name", "minProduct", "defaultProduct", "mode") VALUES ($1 || ' Station', $2, 1, 3);

INSERT INTO "static"."Locations" ("id", "name", "minProduct", "defaultProduct", "mode") VALUES (0, 'Online', 0, 0, 0); -- only for top up and pass purchases

-- CBD/City Loop
EXECUTE insert_location('Flinders Street', 1);
EXECUTE insert_location('Southern Cross', 1);
EXECUTE insert_location('Flagstaff', 1);
EXECUTE insert_location('Melbourne Central', 1);
EXECUTE insert_location('Parliament', 1);

-- Clifton Hill Group
EXECUTE insert_location('Jolimont', 1);
EXECUTE insert_location('West Richmond', 1);
EXECUTE insert_location('North Richmond', 1);
EXECUTE insert_location('Collingwood', 1);
EXECUTE insert_location('Victoria Park', 1);
EXECUTE insert_location('Clifton Hill', 1);

-- Mernda Line
EXECUTE insert_location('Rushall', 1);
EXECUTE insert_location('Merri', 1);
EXECUTE insert_location('Northcote', 1);
EXECUTE insert_location('Croxton', 1);
EXECUTE insert_location('Thornbury', 1);
EXECUTE insert_location('Bell', 1);
EXECUTE insert_location('Preston', 3);
EXECUTE insert_location('Regent', 3);
EXECUTE insert_location('Reservoir', 3);
EXECUTE insert_location('Ruthven', 5);
EXECUTE insert_location('Keon Park', 5);
EXECUTE insert_location('Thomastown', 5);
EXECUTE insert_location('Lalor', 5);
EXECUTE insert_location('Epping', 5);
EXECUTE insert_location('South Morang', 5);
EXECUTE insert_location('Middle Gorge', 5);
EXECUTE insert_location('Hawkstowe', 5);
EXECUTE insert_location('Mernda', 5);

-- Hurstbridge Line
EXECUTE insert_location('Westgarth', 1);
EXECUTE insert_location('Dennis', 1);
EXECUTE insert_location('Fairfield', 1);
EXECUTE insert_location('Alphington', 1);
EXECUTE insert_location('Darebin', 1);
EXECUTE insert_location('Ivanhoe', 3);
EXECUTE insert_location('Eaglemont', 3);
EXECUTE insert_location('Heidelberg', 3);
EXECUTE insert_location('Rosanna', 5);
EXECUTE insert_location('Macleod', 5);
EXECUTE insert_location('Watsonia', 5);
EXECUTE insert_location('Greensborough', 5);
EXECUTE insert_location('Montmorency', 5);
EXECUTE insert_location('Eltham', 5);
EXECUTE insert_location('Diamond Creek', 5);
EXECUTE insert_location('Wattle Glen', 5);
EXECUTE insert_location('Hurstbridge', 5);

-- Burnley Group
EXECUTE insert_location('Richmond', 1);
EXECUTE insert_location('East Richmond', 1);
EXECUTE insert_location('Burnley', 1);

-- Glen Waverley Line
EXECUTE insert_location('Heyington', 1);
EXECUTE insert_location('Kooyong', 1);
EXECUTE insert_location('Tooronga', 1);
EXECUTE insert_location('Gardiner', 1);
EXECUTE insert_location('Glen Iris', 1);
EXECUTE insert_location('Darling', 3);
EXECUTE insert_location('East Malvern', 3);
EXECUTE insert_location('Holmesglen', 3);
EXECUTE insert_location('Jordanville', 5);
EXECUTE insert_location('Mount Waverley', 5);
EXECUTE insert_location('Syndal', 5);
EXECUTE insert_location('Glen Waverley', 5);

-- Camberwell Group
EXECUTE insert_location('Hawthorn', 1);
EXECUTE insert_location('Glenferrie', 1);
EXECUTE insert_location('Auburn', 1);
EXECUTE insert_location('Camberwell', 1);

-- Alamein Line
EXECUTE insert_location('Riversdale', 1);
EXECUTE insert_location('Willison', 1);
EXECUTE insert_location('Hartwell', 1);
EXECUTE insert_location('Burwood', 1);
EXECUTE insert_location('Ashburton', 1);
EXECUTE insert_location('Alamein', 1);

-- Ringwood Group
EXECUTE insert_location('East Camberwell', 1);
EXECUTE insert_location('Canterbury', 3);
EXECUTE insert_location('Chatham', 3);
EXECUTE insert_location('Union', 3);
EXECUTE insert_location('Box Hill', 5);
EXECUTE insert_location('Laburnum', 5);
EXECUTE insert_location('Blackburn', 5);
EXECUTE insert_location('Nunawading', 5);
EXECUTE insert_location('Mitcham', 5);
EXECUTE insert_location('Heatherdale', 5);
EXECUTE insert_location('Ringwood', 5);

-- Lilydale Line
EXECUTE insert_location('Ringwood East', 5);
EXECUTE insert_location('Croydon', 5);
EXECUTE insert_location('Mooroolbark', 5);
EXECUTE insert_location('Lilydale', 5);

-- Belgrave Line
EXECUTE insert_location('Heathmont', 5);
EXECUTE insert_location('Bayswater', 5);
EXECUTE insert_location('Boronia', 5);
EXECUTE insert_location('Ferntree Gully', 5);
EXECUTE insert_location('Upper Ferntree Gully', 5);
EXECUTE insert_location('Upwey', 5);
EXECUTE insert_location('Tecoma', 5);
EXECUTE insert_location('Belgrave', 5);

-- Sandringham Line
EXECUTE insert_location('South Yarra', 1);
EXECUTE insert_location('Prahran', 1);
EXECUTE insert_location('Windsor', 1);
EXECUTE insert_location('Balaclava', 1);
EXECUTE insert_location('Ripponlea', 1);
EXECUTE insert_location('Elsternwick', 1);
EXECUTE insert_location('Gardenvale', 1);
EXECUTE insert_location('North Brighton', 3);
EXECUTE insert_location('Middle Brighton', 3);
EXECUTE insert_location('Brighton Beach', 3);
EXECUTE insert_location('Hampton', 5);
EXECUTE insert_location('Sandringham', 5);

-- Caulfield Group
EXECUTE insert_location('Hawksburn', 1);
EXECUTE insert_location('Toorak', 1);
EXECUTE insert_location('Armadale', 1);
EXECUTE insert_location('Malvern', 1);
EXECUTE insert_location('Caulfield', 1);

-- Frankston Line
EXECUTE insert_location('Glen Huntly', 1);
EXECUTE insert_location('Ormond', 3);
EXECUTE insert_location('McKinnon', 3);
EXECUTE insert_location('Bentleigh', 3);
EXECUTE insert_location('Patterson', 5);
EXECUTE insert_location('Moorabbin', 5);
EXECUTE insert_location('Highett', 5);
EXECUTE insert_location('Southland', 5);
EXECUTE insert_location('Cheltenham', 5);
EXECUTE insert_location('Mentone', 5);
EXECUTE insert_location('Parkdale', 5);
EXECUTE insert_location('Mordialloc', 5);
EXECUTE insert_location('Aspendale', 5);
EXECUTE insert_location('Edithvale', 5);
EXECUTE insert_location('Chelsea', 5);
EXECUTE insert_location('Bonbeach', 5);
EXECUTE insert_location('Carrum', 5);
EXECUTE insert_location('Seaford', 5);
EXECUTE insert_location('Kananook', 5);
EXECUTE insert_location('Frankston', 5);

-- Stony Point Line
EXECUTE insert_location('Leawarra', 5);
EXECUTE insert_location('Baxter', 5);
EXECUTE insert_location('Somerville', 5);
EXECUTE insert_location('Tyabb', 5);
EXECUTE insert_location('Hastings', 5);
EXECUTE insert_location('Bittern', 5);
EXECUTE insert_location('Morradoo', 5);
EXECUTE insert_location('Crib Point', 5);
EXECUTE insert_location('Stony Point', 5);

-- Dandenong Group
EXECUTE insert_location('Carnegie', 1);
EXECUTE insert_location('Murrumbeena', 1);
EXECUTE insert_location('Hughesdale', 3);
EXECUTE insert_location('Oakleigh', 3);
EXECUTE insert_location('Huntingdale', 3);
EXECUTE insert_location('Clayton', 5);
EXECUTE insert_location('Westall', 5);
EXECUTE insert_location('Springvale', 5);
EXECUTE insert_location('Sandown Park', 5);
EXECUTE insert_location('Noble Park', 5);
EXECUTE insert_location('Yarraman', 5);
EXECUTE insert_location('Dandenong', 5);

-- Cranbourne Line
EXECUTE insert_location('Lynbrook', 5);
EXECUTE insert_location('Merinda Park', 5);
EXECUTE insert_location('Cranbourne', 5);

-- (East) Pakenham Line
EXECUTE insert_location('Hallam', 5);
EXECUTE insert_location('Narre Warren', 5);
EXECUTE insert_location('Berwick', 5);
EXECUTE insert_location('Beaconsfield', 5);
EXECUTE insert_location('Officer', 5);
EXECUTE insert_location('Cardinia Road', 5);
EXECUTE insert_location('Pakenham', 5);
EXECUTE insert_location('East Pakenham', 5);

-- Northern Group + Flemington Racecourse Line
EXECUTE insert_location('North Melbourne', 1);
EXECUTE insert_location('Kensington', 1);
EXECUTE insert_location('Newmarket', 1);
EXECUTE insert_location('Showgrounds', 1);
EXECUTE insert_location('Flemington Racecourse', 1);

-- Craigieburn Line
EXECUTE insert_location('Ascot Vale', 1);
EXECUTE insert_location('Moonee Ponds', 1);
EXECUTE insert_location('Essendon', 1);
EXECUTE insert_location('Glenbervie', 1);
EXECUTE insert_location('Strathmore', 1);
EXECUTE insert_location('Pascoe Vale', 3);
EXECUTE insert_location('Oak Park', 3);
EXECUTE insert_location('Glenroy', 3);
EXECUTE insert_location('Jacana', 5);
EXECUTE insert_location('Broadmeadows', 5);
EXECUTE insert_location('Coolaroo', 5);
EXECUTE insert_location('Roxburgh Park', 5);
EXECUTE insert_location('Craigieburn', 5);

-- Upfield Line
EXECUTE insert_location('Macaulay', 1);
EXECUTE insert_location('Flemington Bridge', 1);
EXECUTE insert_location('Royal Park', 1);
EXECUTE insert_location('Jewell', 1);
EXECUTE insert_location('Brunswick', 1);
EXECUTE insert_location('Anstey', 1);
EXECUTE insert_location('Moreland', 1);
EXECUTE insert_location('Coburg', 1);
EXECUTE insert_location('Batman', 3);
EXECUTE insert_location('Merlynston', 3);
EXECUTE insert_location('Fawkner', 3);
EXECUTE insert_location('Gowrie', 5);
EXECUTE insert_location('Upfield', 5);

-- Sunbury Line
EXECUTE insert_location('South Kensington', 1);
EXECUTE insert_location('Footscray', 1);
EXECUTE insert_location('Middle Footscray', 1);
EXECUTE insert_location('West Footscray', 1);
EXECUTE insert_location('Tottenham', 1);
EXECUTE insert_location('Sunshine', 3);
EXECUTE insert_location('Albion', 3);
EXECUTE insert_location('Ginifer', 5);
EXECUTE insert_location('St Albans', 5);
EXECUTE insert_location('Keilor Plains', 5);
EXECUTE insert_location('Watergardens', 5);
EXECUTE insert_location('Diggers Rest', 5);
EXECUTE insert_location('Sunbury', 5);

-- Newport Group
EXECUTE insert_location('Seddon', 1);
EXECUTE insert_location('Yarraville', 1);
EXECUTE insert_location('Spotswood', 1);
EXECUTE insert_location('Newport', 1);

-- Williamstown Line
EXECUTE insert_location('North Williamstown', 1);
EXECUTE insert_location('Wlliamstown Beach', 1);
EXECUTE insert_location('Williamstown', 1);

-- Werribee Line
EXECUTE insert_location('Seaholme', 1);
EXECUTE insert_location('Altona', 3);
EXECUTE insert_location('Wetona', 3);
EXECUTE insert_location('Laverton', 3);
EXECUTE insert_location('Aircraft', 5);
EXECUTE insert_location('Williams Landing', 5);
EXECUTE insert_location('Hoppers Crossing', 5);
EXECUTE insert_location('Werribee', 5);

-- triggers.sql
CREATE OR REPLACE FUNCTION "auth"."notify"()
    RETURNS TRIGGER
    LANGUAGE PLPGSQL
AS $on_change$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        PERFORM pg_notify('auth_del', '{"id":"' || OLD."key"::text || '"}');
        RETURN OLD;
    ELSE
        PERFORM pg_notify('auth_add', '{"id":"' || NEW."key"::text || '"}');
        RETURN NEW;
    END IF;
END;
$on_change$;

DROP TRIGGER IF EXISTS on_change ON "auth"."Keys";
CREATE TRIGGER on_change
    AFTER INSERT OR DELETE ON "auth"."Keys"
    FOR EACH ROW EXECUTE PROCEDURE "auth"."notify"();
