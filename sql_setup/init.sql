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
