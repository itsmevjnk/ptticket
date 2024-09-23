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
