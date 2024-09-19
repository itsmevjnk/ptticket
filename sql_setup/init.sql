DROP DATABASE IF EXISTS "ptticket";
CREATE DATABASE "ptticket";

DROP GROUP IF EXISTS "ptticket";
CREATE GROUP "ptticket";
DROP USER IF EXISTS "static";
DROP USER IF EXISTS "dynamic";
CREATE USER "static" ENCRYPTED PASSWORD 'ptticket_static' IN GROUP "ptticket";
CREATE USER "dynamic" ENCRYPTED PASSWORD 'ptticket_dynamic' IN GROUP "ptticket";
