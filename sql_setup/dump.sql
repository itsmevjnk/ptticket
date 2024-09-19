--
-- PostgreSQL database dump
--

-- Dumped from database version 12.20
-- Dumped by pg_dump version 12.20

-- Started on 2024-09-19 13:26:17 UTC

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 3173 (class 1262 OID 16384)
-- Name: ptticket; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE ptticket WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'en_US.utf8' LC_CTYPE = 'en_US.utf8';


ALTER DATABASE ptticket OWNER TO postgres;

\connect ptticket

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 8 (class 2615 OID 16504)
-- Name: dynamic; Type: SCHEMA; Schema: -; Owner: dynamic
--

CREATE SCHEMA dynamic;


ALTER SCHEMA dynamic OWNER TO dynamic;

--
-- TOC entry 10 (class 2615 OID 16503)
-- Name: static; Type: SCHEMA; Schema: -; Owner: static
--

CREATE SCHEMA static;


ALTER SCHEMA static OWNER TO static;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 217 (class 1259 OID 16644)
-- Name: Passes; Type: TABLE; Schema: dynamic; Owner: postgres
--

CREATE TABLE dynamic."Passes" (
    "transactionID" uuid NOT NULL,
    "ticketID" uuid,
    duration integer NOT NULL,
    "activationDate" date,
    product integer
);


ALTER TABLE dynamic."Passes" OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 16632)
-- Name: PhysicalTickets; Type: TABLE; Schema: dynamic; Owner: postgres
--

CREATE TABLE dynamic."PhysicalTickets" (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    type character varying(8) NOT NULL,
    disabled boolean DEFAULT false NOT NULL,
    "expiryDate" date,
    "ticketID" uuid
);


ALTER TABLE dynamic."PhysicalTickets" OWNER TO postgres;

--
-- TOC entry 214 (class 1259 OID 16578)
-- Name: Tickets; Type: TABLE; Schema: dynamic; Owner: postgres
--

CREATE TABLE dynamic."Tickets" (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    "fareType" integer,
    balance integer DEFAULT 0 NOT NULL,
    "dailyExpenditure" integer DEFAULT 0 NOT NULL,
    "currentProduct" integer DEFAULT 0,
    "touchedOn" integer DEFAULT 0,
    "prodValidated" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "prodDuration" integer DEFAULT 0 NOT NULL
);


ALTER TABLE dynamic."Tickets" OWNER TO postgres;

--
-- TOC entry 215 (class 1259 OID 16605)
-- Name: Transactions; Type: TABLE; Schema: dynamic; Owner: postgres
--

CREATE TABLE dynamic."Transactions" (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    "ticketID" uuid,
    "timestamp" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    type integer,
    location integer,
    product integer,
    balance integer NOT NULL
);


ALTER TABLE dynamic."Transactions" OWNER TO postgres;

--
-- TOC entry 213 (class 1259 OID 16568)
-- Name: DailyFareCaps; Type: TABLE; Schema: static; Owner: postgres
--

CREATE TABLE static."DailyFareCaps" (
    "dateCondition" integer NOT NULL,
    "fareType" integer NOT NULL,
    "fareCap" integer NOT NULL
);


ALTER TABLE static."DailyFareCaps" OWNER TO postgres;

--
-- TOC entry 205 (class 1259 OID 16505)
-- Name: FareTypes; Type: TABLE; Schema: static; Owner: postgres
--

CREATE TABLE static."FareTypes" (
    type integer NOT NULL,
    name character varying(48) NOT NULL
);


ALTER TABLE static."FareTypes" OWNER TO postgres;

--
-- TOC entry 211 (class 1259 OID 16532)
-- Name: Locations; Type: TABLE; Schema: static; Owner: postgres
--

CREATE TABLE static."Locations" (
    id integer NOT NULL,
    name character varying(64),
    mode integer,
    "minProduct" integer,
    "defaultProduct" integer
);


ALTER TABLE static."Locations" OWNER TO postgres;

--
-- TOC entry 210 (class 1259 OID 16530)
-- Name: Locations_id_seq; Type: SEQUENCE; Schema: static; Owner: postgres
--

CREATE SEQUENCE static."Locations_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE static."Locations_id_seq" OWNER TO postgres;

--
-- TOC entry 3183 (class 0 OID 0)
-- Dependencies: 210
-- Name: Locations_id_seq; Type: SEQUENCE OWNED BY; Schema: static; Owner: postgres
--

ALTER SEQUENCE static."Locations_id_seq" OWNED BY static."Locations".id;


--
-- TOC entry 212 (class 1259 OID 16553)
-- Name: ProductFares; Type: TABLE; Schema: static; Owner: postgres
--

CREATE TABLE static."ProductFares" (
    "productID" integer NOT NULL,
    "fareType" integer NOT NULL,
    "dateCondition" integer NOT NULL,
    fare integer NOT NULL
);


ALTER TABLE static."ProductFares" OWNER TO postgres;

--
-- TOC entry 206 (class 1259 OID 16510)
-- Name: Products; Type: TABLE; Schema: static; Owner: postgres
--

CREATE TABLE static."Products" (
    id integer NOT NULL,
    name character varying(48) NOT NULL,
    "fromZone" integer NOT NULL,
    "toZone" integer NOT NULL,
    duration integer NOT NULL
);


ALTER TABLE static."Products" OWNER TO postgres;

--
-- TOC entry 208 (class 1259 OID 16520)
-- Name: SpecialDates; Type: TABLE; Schema: static; Owner: postgres
--

CREATE TABLE static."SpecialDates" (
    "from" date NOT NULL,
    "to" date NOT NULL,
    "dateCondition" integer NOT NULL,
    description character varying(48)
);


ALTER TABLE static."SpecialDates" OWNER TO postgres;

--
-- TOC entry 207 (class 1259 OID 16515)
-- Name: TransactionTypes; Type: TABLE; Schema: static; Owner: postgres
--

CREATE TABLE static."TransactionTypes" (
    type integer NOT NULL,
    name character varying(48) NOT NULL
);


ALTER TABLE static."TransactionTypes" OWNER TO postgres;

--
-- TOC entry 209 (class 1259 OID 16525)
-- Name: TransportModes; Type: TABLE; Schema: static; Owner: postgres
--

CREATE TABLE static."TransportModes" (
    mode integer NOT NULL,
    name character varying(24) NOT NULL
);


ALTER TABLE static."TransportModes" OWNER TO postgres;

--
-- TOC entry 2976 (class 2604 OID 16535)
-- Name: Locations id; Type: DEFAULT; Schema: static; Owner: postgres
--

ALTER TABLE ONLY static."Locations" ALTER COLUMN id SET DEFAULT nextval('static."Locations_id_seq"'::regclass);


--
-- TOC entry 3167 (class 0 OID 16644)
-- Dependencies: 217
-- Data for Name: Passes; Type: TABLE DATA; Schema: dynamic; Owner: postgres
--



--
-- TOC entry 3166 (class 0 OID 16632)
-- Dependencies: 216
-- Data for Name: PhysicalTickets; Type: TABLE DATA; Schema: dynamic; Owner: postgres
--



--
-- TOC entry 3164 (class 0 OID 16578)
-- Dependencies: 214
-- Data for Name: Tickets; Type: TABLE DATA; Schema: dynamic; Owner: postgres
--



--
-- TOC entry 3165 (class 0 OID 16605)
-- Dependencies: 215
-- Data for Name: Transactions; Type: TABLE DATA; Schema: dynamic; Owner: postgres
--



--
-- TOC entry 3163 (class 0 OID 16568)
-- Dependencies: 213
-- Data for Name: DailyFareCaps; Type: TABLE DATA; Schema: static; Owner: postgres
--

INSERT INTO static."DailyFareCaps" VALUES (0, 0, 1060);
INSERT INTO static."DailyFareCaps" VALUES (1, 0, 720);
INSERT INTO static."DailyFareCaps" VALUES (0, 1, 530);
INSERT INTO static."DailyFareCaps" VALUES (1, 1, 360);
INSERT INTO static."DailyFareCaps" VALUES (0, 2, 530);
INSERT INTO static."DailyFareCaps" VALUES (1, 2, 360);
INSERT INTO static."DailyFareCaps" VALUES (0, 3, 530);
INSERT INTO static."DailyFareCaps" VALUES (1, 3, 360);
INSERT INTO static."DailyFareCaps" VALUES (2, 3, 0);
INSERT INTO static."DailyFareCaps" VALUES (0, 4, 530);
INSERT INTO static."DailyFareCaps" VALUES (1, 4, 360);
INSERT INTO static."DailyFareCaps" VALUES (0, 5, 530);
INSERT INTO static."DailyFareCaps" VALUES (1, 5, 360);
INSERT INTO static."DailyFareCaps" VALUES (4, 5, 0);
INSERT INTO static."DailyFareCaps" VALUES (0, 6, 530);
INSERT INTO static."DailyFareCaps" VALUES (1, 6, 360);
INSERT INTO static."DailyFareCaps" VALUES (8, 6, 0);


--
-- TOC entry 3155 (class 0 OID 16505)
-- Dependencies: 205
-- Data for Name: FareTypes; Type: TABLE DATA; Schema: static; Owner: postgres
--

INSERT INTO static."FareTypes" VALUES (0, 'Full Fare');
INSERT INTO static."FareTypes" VALUES (1, 'Concession');
INSERT INTO static."FareTypes" VALUES (2, 'Child');
INSERT INTO static."FareTypes" VALUES (3, 'Carers');
INSERT INTO static."FareTypes" VALUES (4, 'Disability Support Pension');
INSERT INTO static."FareTypes" VALUES (5, 'Seniors');
INSERT INTO static."FareTypes" VALUES (6, 'War Veterans/Widow(er)s');


--
-- TOC entry 3161 (class 0 OID 16532)
-- Dependencies: 211
-- Data for Name: Locations; Type: TABLE DATA; Schema: static; Owner: postgres
--

INSERT INTO static."Locations" VALUES (0, 'Online', 0, 0, 0);
INSERT INTO static."Locations" VALUES (1, 'Flinders Street Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (2, 'Southern Cross Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (3, 'Flagstaff Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (4, 'Melbourne Central Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (5, 'Parliament Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (6, 'Jolimont Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (7, 'West Richmond Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (8, 'North Richmond Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (9, 'Collingwood Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (10, 'Victoria Park Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (11, 'Clifton Hill Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (12, 'Rushall Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (13, 'Merri Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (14, 'Northcote Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (15, 'Croxton Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (16, 'Thornbury Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (17, 'Bell Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (18, 'Preston Station', 3, 3, 1);
INSERT INTO static."Locations" VALUES (19, 'Regent Station', 3, 3, 1);
INSERT INTO static."Locations" VALUES (20, 'Reservoir Station', 3, 3, 1);
INSERT INTO static."Locations" VALUES (21, 'Ruthven Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (22, 'Keon Park Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (23, 'Thomastown Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (24, 'Lalor Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (25, 'Epping Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (26, 'South Morang Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (27, 'Middle Gorge Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (28, 'Hawkstowe Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (29, 'Mernda Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (30, 'Westgarth Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (31, 'Dennis Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (32, 'Fairfield Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (33, 'Alphington Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (34, 'Darebin Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (35, 'Ivanhoe Station', 3, 3, 1);
INSERT INTO static."Locations" VALUES (36, 'Eaglemont Station', 3, 3, 1);
INSERT INTO static."Locations" VALUES (37, 'Heidelberg Station', 3, 3, 1);
INSERT INTO static."Locations" VALUES (38, 'Rosanna Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (39, 'Macleod Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (40, 'Watsonia Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (41, 'Greensborough Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (42, 'Montmorency Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (43, 'Eltham Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (44, 'Diamond Creek Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (45, 'Wattle Glen Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (46, 'Hurstbridge Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (47, 'Richmond Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (48, 'East Richmond Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (49, 'Burnley Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (50, 'Heyington Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (51, 'Kooyong Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (52, 'Tooronga Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (53, 'Gardiner Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (54, 'Glen Iris Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (55, 'Darling Station', 3, 3, 1);
INSERT INTO static."Locations" VALUES (56, 'East Malvern Station', 3, 3, 1);
INSERT INTO static."Locations" VALUES (57, 'Holmesglen Station', 3, 3, 1);
INSERT INTO static."Locations" VALUES (58, 'Jordanville Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (59, 'Mount Waverley Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (60, 'Syndal Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (61, 'Glen Waverley Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (62, 'Hawthorn Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (63, 'Glenferrie Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (64, 'Auburn Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (65, 'Camberwell Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (66, 'Riversdale Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (67, 'Willison Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (68, 'Hartwell Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (69, 'Burwood Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (70, 'Ashburton Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (71, 'Alamein Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (72, 'East Camberwell Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (73, 'Canterbury Station', 3, 3, 1);
INSERT INTO static."Locations" VALUES (74, 'Chatham Station', 3, 3, 1);
INSERT INTO static."Locations" VALUES (75, 'Union Station', 3, 3, 1);
INSERT INTO static."Locations" VALUES (76, 'Box Hill Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (77, 'Laburnum Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (78, 'Blackburn Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (79, 'Nunawading Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (80, 'Mitcham Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (81, 'Heatherdale Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (82, 'Ringwood Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (83, 'Ringwood East Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (84, 'Croydon Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (85, 'Mooroolbark Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (86, 'Lilydale Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (87, 'Heathmont Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (88, 'Bayswater Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (89, 'Boronia Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (90, 'Ferntree Gully Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (91, 'Upper Ferntree Gully Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (92, 'Upwey Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (93, 'Tecoma Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (94, 'Belgrave Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (95, 'South Yarra Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (96, 'Prahran Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (97, 'Windsor Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (98, 'Balaclava Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (99, 'Ripponlea Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (100, 'Elsternwick Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (101, 'Gardenvale Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (102, 'North Brighton Station', 3, 3, 1);
INSERT INTO static."Locations" VALUES (103, 'Middle Brighton Station', 3, 3, 1);
INSERT INTO static."Locations" VALUES (104, 'Brighton Beach Station', 3, 3, 1);
INSERT INTO static."Locations" VALUES (105, 'Hampton Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (106, 'Sandringham Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (107, 'Hawksburn Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (108, 'Toorak Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (109, 'Armadale Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (110, 'Malvern Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (111, 'Caulfield Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (112, 'Glen Huntly Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (113, 'Ormond Station', 3, 3, 1);
INSERT INTO static."Locations" VALUES (114, 'McKinnon Station', 3, 3, 1);
INSERT INTO static."Locations" VALUES (115, 'Bentleigh Station', 3, 3, 1);
INSERT INTO static."Locations" VALUES (116, 'Patterson Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (117, 'Moorabbin Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (118, 'Highett Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (119, 'Southland Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (120, 'Cheltenham Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (121, 'Mentone Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (122, 'Parkdale Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (123, 'Mordialloc Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (124, 'Aspendale Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (125, 'Edithvale Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (126, 'Chelsea Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (127, 'Bonbeach Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (128, 'Carrum Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (129, 'Seaford Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (130, 'Kananook Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (131, 'Frankston Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (132, 'Leawarra Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (133, 'Baxter Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (134, 'Somerville Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (135, 'Tyabb Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (136, 'Hastings Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (137, 'Bittern Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (138, 'Morradoo Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (139, 'Crib Point Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (140, 'Stony Point Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (141, 'Carnegie Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (142, 'Murrumbeena Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (143, 'Hughesdale Station', 3, 3, 1);
INSERT INTO static."Locations" VALUES (144, 'Oakleigh Station', 3, 3, 1);
INSERT INTO static."Locations" VALUES (145, 'Huntingdale Station', 3, 3, 1);
INSERT INTO static."Locations" VALUES (146, 'Clayton Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (147, 'Westall Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (148, 'Springvale Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (149, 'Sandown Park Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (150, 'Noble Park Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (151, 'Yarraman Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (152, 'Dandenong Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (153, 'Lynbrook Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (154, 'Merinda Park Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (155, 'Cranbourne Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (156, 'Hallam Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (157, 'Narre Warren Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (158, 'Berwick Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (159, 'Beaconsfield Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (160, 'Officer Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (161, 'Cardinia Road Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (162, 'Pakenham Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (163, 'East Pakenham Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (164, 'North Melbourne Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (165, 'Kensington Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (166, 'Newmarket Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (167, 'Showgrounds Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (168, 'Flemington Racecourse Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (169, 'Ascot Vale Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (170, 'Moonee Ponds Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (171, 'Essendon Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (172, 'Glenbervie Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (173, 'Strathmore Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (174, 'Pascoe Vale Station', 3, 3, 1);
INSERT INTO static."Locations" VALUES (175, 'Oak Park Station', 3, 3, 1);
INSERT INTO static."Locations" VALUES (176, 'Glenroy Station', 3, 3, 1);
INSERT INTO static."Locations" VALUES (177, 'Jacana Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (178, 'Broadmeadows Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (179, 'Coolaroo Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (180, 'Roxburgh Park Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (181, 'Craigieburn Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (182, 'Macaulay Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (183, 'Flemington Bridge Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (184, 'Royal Park Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (185, 'Jewell Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (186, 'Brunswick Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (187, 'Anstey Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (188, 'Moreland Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (189, 'Coburg Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (190, 'Batman Station', 3, 3, 1);
INSERT INTO static."Locations" VALUES (191, 'Merlynston Station', 3, 3, 1);
INSERT INTO static."Locations" VALUES (192, 'Fawkner Station', 3, 3, 1);
INSERT INTO static."Locations" VALUES (193, 'Gowrie Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (194, 'Upfield Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (195, 'South Kensington Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (196, 'Footscray Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (197, 'Middle Footscray Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (198, 'West Footscray Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (199, 'Tottenham Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (200, 'Sunshine Station', 3, 3, 1);
INSERT INTO static."Locations" VALUES (201, 'Albion Station', 3, 3, 1);
INSERT INTO static."Locations" VALUES (202, 'Ginifer Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (203, 'St Albans Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (204, 'Keilor Plains Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (205, 'Watergardens Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (206, 'Diggers Rest Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (207, 'Sunbury Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (208, 'Seddon Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (209, 'Yarraville Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (210, 'Spotswood Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (211, 'Newport Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (212, 'North Williamstown Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (213, 'Wlliamstown Beach Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (214, 'Williamstown Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (215, 'Seaholme Station', 3, 1, 1);
INSERT INTO static."Locations" VALUES (216, 'Altona Station', 3, 3, 1);
INSERT INTO static."Locations" VALUES (217, 'Wetona Station', 3, 3, 1);
INSERT INTO static."Locations" VALUES (218, 'Laverton Station', 3, 3, 1);
INSERT INTO static."Locations" VALUES (219, 'Aircraft Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (220, 'Williams Landing Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (221, 'Hoppers Crossing Station', 3, 5, 1);
INSERT INTO static."Locations" VALUES (222, 'Werribee Station', 3, 5, 1);


--
-- TOC entry 3162 (class 0 OID 16553)
-- Dependencies: 212
-- Data for Name: ProductFares; Type: TABLE DATA; Schema: static; Owner: postgres
--

INSERT INTO static."ProductFares" VALUES (1, 0, 0, 530);
INSERT INTO static."ProductFares" VALUES (2, 0, 0, 900);
INSERT INTO static."ProductFares" VALUES (4, 0, 0, 1060);
INSERT INTO static."ProductFares" VALUES (5, 0, 0, 330);
INSERT INTO static."ProductFares" VALUES (6, 0, 0, 280);
INSERT INTO static."ProductFares" VALUES (7, 0, 0, 280);
INSERT INTO static."ProductFares" VALUES (8, 0, 0, 280);
INSERT INTO static."ProductFares" VALUES (9, 0, 0, 280);
INSERT INTO static."ProductFares" VALUES (10, 0, 0, 280);
INSERT INTO static."ProductFares" VALUES (11, 0, 0, 280);
INSERT INTO static."ProductFares" VALUES (12, 0, 0, 280);
INSERT INTO static."ProductFares" VALUES (13, 0, 0, 280);
INSERT INTO static."ProductFares" VALUES (14, 0, 0, 280);
INSERT INTO static."ProductFares" VALUES (15, 0, 0, 280);
INSERT INTO static."ProductFares" VALUES (16, 0, 0, 280);
INSERT INTO static."ProductFares" VALUES (17, 0, 0, 280);
INSERT INTO static."ProductFares" VALUES (18, 0, 0, 280);
INSERT INTO static."ProductFares" VALUES (19, 0, 0, 380);
INSERT INTO static."ProductFares" VALUES (20, 0, 0, 380);
INSERT INTO static."ProductFares" VALUES (21, 0, 0, 380);
INSERT INTO static."ProductFares" VALUES (22, 0, 0, 380);
INSERT INTO static."ProductFares" VALUES (23, 0, 0, 380);
INSERT INTO static."ProductFares" VALUES (24, 0, 0, 380);
INSERT INTO static."ProductFares" VALUES (25, 0, 0, 380);
INSERT INTO static."ProductFares" VALUES (26, 0, 0, 380);
INSERT INTO static."ProductFares" VALUES (27, 0, 0, 380);
INSERT INTO static."ProductFares" VALUES (28, 0, 0, 380);
INSERT INTO static."ProductFares" VALUES (29, 0, 0, 380);
INSERT INTO static."ProductFares" VALUES (30, 0, 0, 380);
INSERT INTO static."ProductFares" VALUES (31, 0, 0, 380);
INSERT INTO static."ProductFares" VALUES (32, 0, 0, 420);
INSERT INTO static."ProductFares" VALUES (33, 0, 0, 420);
INSERT INTO static."ProductFares" VALUES (34, 0, 0, 420);
INSERT INTO static."ProductFares" VALUES (35, 0, 0, 420);
INSERT INTO static."ProductFares" VALUES (36, 0, 0, 420);
INSERT INTO static."ProductFares" VALUES (37, 0, 0, 420);
INSERT INTO static."ProductFares" VALUES (38, 0, 0, 420);
INSERT INTO static."ProductFares" VALUES (39, 0, 0, 420);
INSERT INTO static."ProductFares" VALUES (40, 0, 0, 420);
INSERT INTO static."ProductFares" VALUES (41, 0, 0, 420);
INSERT INTO static."ProductFares" VALUES (42, 0, 0, 420);
INSERT INTO static."ProductFares" VALUES (43, 0, 0, 420);
INSERT INTO static."ProductFares" VALUES (44, 0, 0, 520);
INSERT INTO static."ProductFares" VALUES (45, 0, 0, 520);
INSERT INTO static."ProductFares" VALUES (46, 0, 0, 520);
INSERT INTO static."ProductFares" VALUES (47, 0, 0, 520);
INSERT INTO static."ProductFares" VALUES (48, 0, 0, 520);
INSERT INTO static."ProductFares" VALUES (49, 0, 0, 520);
INSERT INTO static."ProductFares" VALUES (50, 0, 0, 520);
INSERT INTO static."ProductFares" VALUES (51, 0, 0, 520);
INSERT INTO static."ProductFares" VALUES (52, 0, 0, 520);
INSERT INTO static."ProductFares" VALUES (53, 0, 0, 520);
INSERT INTO static."ProductFares" VALUES (54, 0, 0, 520);
INSERT INTO static."ProductFares" VALUES (55, 0, 0, 600);
INSERT INTO static."ProductFares" VALUES (56, 0, 0, 600);
INSERT INTO static."ProductFares" VALUES (57, 0, 0, 600);
INSERT INTO static."ProductFares" VALUES (58, 0, 0, 600);
INSERT INTO static."ProductFares" VALUES (59, 0, 0, 600);
INSERT INTO static."ProductFares" VALUES (60, 0, 0, 600);
INSERT INTO static."ProductFares" VALUES (61, 0, 0, 600);
INSERT INTO static."ProductFares" VALUES (62, 0, 0, 600);
INSERT INTO static."ProductFares" VALUES (63, 0, 0, 600);
INSERT INTO static."ProductFares" VALUES (64, 0, 0, 600);
INSERT INTO static."ProductFares" VALUES (65, 0, 0, 740);
INSERT INTO static."ProductFares" VALUES (66, 0, 0, 740);
INSERT INTO static."ProductFares" VALUES (67, 0, 0, 740);
INSERT INTO static."ProductFares" VALUES (68, 0, 0, 740);
INSERT INTO static."ProductFares" VALUES (69, 0, 0, 740);
INSERT INTO static."ProductFares" VALUES (70, 0, 0, 740);
INSERT INTO static."ProductFares" VALUES (71, 0, 0, 740);
INSERT INTO static."ProductFares" VALUES (72, 0, 0, 740);
INSERT INTO static."ProductFares" VALUES (73, 0, 0, 740);
INSERT INTO static."ProductFares" VALUES (74, 0, 0, 900);
INSERT INTO static."ProductFares" VALUES (75, 0, 0, 900);
INSERT INTO static."ProductFares" VALUES (76, 0, 0, 900);
INSERT INTO static."ProductFares" VALUES (77, 0, 0, 900);
INSERT INTO static."ProductFares" VALUES (78, 0, 0, 900);
INSERT INTO static."ProductFares" VALUES (79, 0, 0, 900);
INSERT INTO static."ProductFares" VALUES (80, 0, 0, 900);
INSERT INTO static."ProductFares" VALUES (81, 0, 0, 900);
INSERT INTO static."ProductFares" VALUES (82, 0, 0, 1060);
INSERT INTO static."ProductFares" VALUES (83, 0, 0, 1060);
INSERT INTO static."ProductFares" VALUES (84, 0, 0, 1060);
INSERT INTO static."ProductFares" VALUES (85, 0, 0, 1060);
INSERT INTO static."ProductFares" VALUES (86, 0, 0, 1060);
INSERT INTO static."ProductFares" VALUES (87, 0, 0, 1060);
INSERT INTO static."ProductFares" VALUES (88, 0, 0, 1060);
INSERT INTO static."ProductFares" VALUES (89, 0, 0, 1060);
INSERT INTO static."ProductFares" VALUES (90, 0, 0, 1060);
INSERT INTO static."ProductFares" VALUES (91, 0, 0, 1060);
INSERT INTO static."ProductFares" VALUES (92, 0, 0, 1060);
INSERT INTO static."ProductFares" VALUES (93, 0, 0, 1060);
INSERT INTO static."ProductFares" VALUES (94, 0, 0, 1060);
INSERT INTO static."ProductFares" VALUES (95, 0, 0, 1060);
INSERT INTO static."ProductFares" VALUES (96, 0, 0, 1060);
INSERT INTO static."ProductFares" VALUES (97, 0, 0, 1060);
INSERT INTO static."ProductFares" VALUES (98, 0, 0, 1060);
INSERT INTO static."ProductFares" VALUES (99, 0, 0, 1060);
INSERT INTO static."ProductFares" VALUES (100, 0, 0, 1060);
INSERT INTO static."ProductFares" VALUES (101, 0, 0, 1060);
INSERT INTO static."ProductFares" VALUES (102, 0, 0, 1060);
INSERT INTO static."ProductFares" VALUES (103, 0, 0, 1060);
INSERT INTO static."ProductFares" VALUES (104, 0, 0, 1060);
INSERT INTO static."ProductFares" VALUES (105, 0, 0, 1060);
INSERT INTO static."ProductFares" VALUES (106, 0, 0, 1060);
INSERT INTO static."ProductFares" VALUES (107, 0, 0, 1060);
INSERT INTO static."ProductFares" VALUES (108, 0, 0, 1060);
INSERT INTO static."ProductFares" VALUES (109, 0, 0, 1060);
INSERT INTO static."ProductFares" VALUES (1, 1, 0, 265);
INSERT INTO static."ProductFares" VALUES (2, 1, 0, 450);
INSERT INTO static."ProductFares" VALUES (4, 1, 0, 530);
INSERT INTO static."ProductFares" VALUES (5, 1, 0, 165);
INSERT INTO static."ProductFares" VALUES (6, 1, 0, 140);
INSERT INTO static."ProductFares" VALUES (7, 1, 0, 140);
INSERT INTO static."ProductFares" VALUES (8, 1, 0, 140);
INSERT INTO static."ProductFares" VALUES (9, 1, 0, 140);
INSERT INTO static."ProductFares" VALUES (10, 1, 0, 140);
INSERT INTO static."ProductFares" VALUES (11, 1, 0, 140);
INSERT INTO static."ProductFares" VALUES (12, 1, 0, 140);
INSERT INTO static."ProductFares" VALUES (13, 1, 0, 140);
INSERT INTO static."ProductFares" VALUES (14, 1, 0, 140);
INSERT INTO static."ProductFares" VALUES (15, 1, 0, 140);
INSERT INTO static."ProductFares" VALUES (16, 1, 0, 140);
INSERT INTO static."ProductFares" VALUES (17, 1, 0, 140);
INSERT INTO static."ProductFares" VALUES (18, 1, 0, 140);
INSERT INTO static."ProductFares" VALUES (19, 1, 0, 190);
INSERT INTO static."ProductFares" VALUES (20, 1, 0, 190);
INSERT INTO static."ProductFares" VALUES (21, 1, 0, 190);
INSERT INTO static."ProductFares" VALUES (22, 1, 0, 190);
INSERT INTO static."ProductFares" VALUES (23, 1, 0, 190);
INSERT INTO static."ProductFares" VALUES (24, 1, 0, 190);
INSERT INTO static."ProductFares" VALUES (25, 1, 0, 190);
INSERT INTO static."ProductFares" VALUES (26, 1, 0, 190);
INSERT INTO static."ProductFares" VALUES (27, 1, 0, 190);
INSERT INTO static."ProductFares" VALUES (28, 1, 0, 190);
INSERT INTO static."ProductFares" VALUES (29, 1, 0, 190);
INSERT INTO static."ProductFares" VALUES (30, 1, 0, 190);
INSERT INTO static."ProductFares" VALUES (31, 1, 0, 190);
INSERT INTO static."ProductFares" VALUES (32, 1, 0, 210);
INSERT INTO static."ProductFares" VALUES (33, 1, 0, 210);
INSERT INTO static."ProductFares" VALUES (34, 1, 0, 210);
INSERT INTO static."ProductFares" VALUES (35, 1, 0, 210);
INSERT INTO static."ProductFares" VALUES (36, 1, 0, 210);
INSERT INTO static."ProductFares" VALUES (37, 1, 0, 210);
INSERT INTO static."ProductFares" VALUES (38, 1, 0, 210);
INSERT INTO static."ProductFares" VALUES (39, 1, 0, 210);
INSERT INTO static."ProductFares" VALUES (40, 1, 0, 210);
INSERT INTO static."ProductFares" VALUES (41, 1, 0, 210);
INSERT INTO static."ProductFares" VALUES (42, 1, 0, 210);
INSERT INTO static."ProductFares" VALUES (43, 1, 0, 210);
INSERT INTO static."ProductFares" VALUES (44, 1, 0, 260);
INSERT INTO static."ProductFares" VALUES (45, 1, 0, 260);
INSERT INTO static."ProductFares" VALUES (46, 1, 0, 260);
INSERT INTO static."ProductFares" VALUES (47, 1, 0, 260);
INSERT INTO static."ProductFares" VALUES (48, 1, 0, 260);
INSERT INTO static."ProductFares" VALUES (49, 1, 0, 260);
INSERT INTO static."ProductFares" VALUES (50, 1, 0, 260);
INSERT INTO static."ProductFares" VALUES (51, 1, 0, 260);
INSERT INTO static."ProductFares" VALUES (52, 1, 0, 260);
INSERT INTO static."ProductFares" VALUES (53, 1, 0, 260);
INSERT INTO static."ProductFares" VALUES (54, 1, 0, 260);
INSERT INTO static."ProductFares" VALUES (55, 1, 0, 300);
INSERT INTO static."ProductFares" VALUES (56, 1, 0, 300);
INSERT INTO static."ProductFares" VALUES (57, 1, 0, 300);
INSERT INTO static."ProductFares" VALUES (58, 1, 0, 300);
INSERT INTO static."ProductFares" VALUES (59, 1, 0, 300);
INSERT INTO static."ProductFares" VALUES (60, 1, 0, 300);
INSERT INTO static."ProductFares" VALUES (61, 1, 0, 300);
INSERT INTO static."ProductFares" VALUES (62, 1, 0, 300);
INSERT INTO static."ProductFares" VALUES (63, 1, 0, 300);
INSERT INTO static."ProductFares" VALUES (64, 1, 0, 300);
INSERT INTO static."ProductFares" VALUES (65, 1, 0, 370);
INSERT INTO static."ProductFares" VALUES (66, 1, 0, 370);
INSERT INTO static."ProductFares" VALUES (67, 1, 0, 370);
INSERT INTO static."ProductFares" VALUES (68, 1, 0, 370);
INSERT INTO static."ProductFares" VALUES (69, 1, 0, 370);
INSERT INTO static."ProductFares" VALUES (70, 1, 0, 370);
INSERT INTO static."ProductFares" VALUES (71, 1, 0, 370);
INSERT INTO static."ProductFares" VALUES (72, 1, 0, 370);
INSERT INTO static."ProductFares" VALUES (73, 1, 0, 370);
INSERT INTO static."ProductFares" VALUES (74, 1, 0, 450);
INSERT INTO static."ProductFares" VALUES (75, 1, 0, 450);
INSERT INTO static."ProductFares" VALUES (76, 1, 0, 450);
INSERT INTO static."ProductFares" VALUES (77, 1, 0, 450);
INSERT INTO static."ProductFares" VALUES (78, 1, 0, 450);
INSERT INTO static."ProductFares" VALUES (79, 1, 0, 450);
INSERT INTO static."ProductFares" VALUES (80, 1, 0, 450);
INSERT INTO static."ProductFares" VALUES (81, 1, 0, 450);
INSERT INTO static."ProductFares" VALUES (82, 1, 0, 530);
INSERT INTO static."ProductFares" VALUES (83, 1, 0, 530);
INSERT INTO static."ProductFares" VALUES (84, 1, 0, 530);
INSERT INTO static."ProductFares" VALUES (85, 1, 0, 530);
INSERT INTO static."ProductFares" VALUES (86, 1, 0, 530);
INSERT INTO static."ProductFares" VALUES (87, 1, 0, 530);
INSERT INTO static."ProductFares" VALUES (88, 1, 0, 530);
INSERT INTO static."ProductFares" VALUES (89, 1, 0, 530);
INSERT INTO static."ProductFares" VALUES (90, 1, 0, 530);
INSERT INTO static."ProductFares" VALUES (91, 1, 0, 530);
INSERT INTO static."ProductFares" VALUES (92, 1, 0, 530);
INSERT INTO static."ProductFares" VALUES (93, 1, 0, 530);
INSERT INTO static."ProductFares" VALUES (94, 1, 0, 530);
INSERT INTO static."ProductFares" VALUES (95, 1, 0, 530);
INSERT INTO static."ProductFares" VALUES (96, 1, 0, 530);
INSERT INTO static."ProductFares" VALUES (97, 1, 0, 530);
INSERT INTO static."ProductFares" VALUES (98, 1, 0, 530);
INSERT INTO static."ProductFares" VALUES (99, 1, 0, 530);
INSERT INTO static."ProductFares" VALUES (100, 1, 0, 530);
INSERT INTO static."ProductFares" VALUES (101, 1, 0, 530);
INSERT INTO static."ProductFares" VALUES (102, 1, 0, 530);
INSERT INTO static."ProductFares" VALUES (103, 1, 0, 530);
INSERT INTO static."ProductFares" VALUES (104, 1, 0, 530);
INSERT INTO static."ProductFares" VALUES (105, 1, 0, 530);
INSERT INTO static."ProductFares" VALUES (106, 1, 0, 530);
INSERT INTO static."ProductFares" VALUES (107, 1, 0, 530);
INSERT INTO static."ProductFares" VALUES (108, 1, 0, 530);
INSERT INTO static."ProductFares" VALUES (109, 1, 0, 530);
INSERT INTO static."ProductFares" VALUES (1, 2, 0, 265);
INSERT INTO static."ProductFares" VALUES (2, 2, 0, 450);
INSERT INTO static."ProductFares" VALUES (4, 2, 0, 530);
INSERT INTO static."ProductFares" VALUES (5, 2, 0, 165);
INSERT INTO static."ProductFares" VALUES (6, 2, 0, 140);
INSERT INTO static."ProductFares" VALUES (7, 2, 0, 140);
INSERT INTO static."ProductFares" VALUES (8, 2, 0, 140);
INSERT INTO static."ProductFares" VALUES (9, 2, 0, 140);
INSERT INTO static."ProductFares" VALUES (10, 2, 0, 140);
INSERT INTO static."ProductFares" VALUES (11, 2, 0, 140);
INSERT INTO static."ProductFares" VALUES (12, 2, 0, 140);
INSERT INTO static."ProductFares" VALUES (13, 2, 0, 140);
INSERT INTO static."ProductFares" VALUES (14, 2, 0, 140);
INSERT INTO static."ProductFares" VALUES (15, 2, 0, 140);
INSERT INTO static."ProductFares" VALUES (16, 2, 0, 140);
INSERT INTO static."ProductFares" VALUES (17, 2, 0, 140);
INSERT INTO static."ProductFares" VALUES (18, 2, 0, 140);
INSERT INTO static."ProductFares" VALUES (19, 2, 0, 190);
INSERT INTO static."ProductFares" VALUES (20, 2, 0, 190);
INSERT INTO static."ProductFares" VALUES (21, 2, 0, 190);
INSERT INTO static."ProductFares" VALUES (22, 2, 0, 190);
INSERT INTO static."ProductFares" VALUES (23, 2, 0, 190);
INSERT INTO static."ProductFares" VALUES (24, 2, 0, 190);
INSERT INTO static."ProductFares" VALUES (25, 2, 0, 190);
INSERT INTO static."ProductFares" VALUES (26, 2, 0, 190);
INSERT INTO static."ProductFares" VALUES (27, 2, 0, 190);
INSERT INTO static."ProductFares" VALUES (28, 2, 0, 190);
INSERT INTO static."ProductFares" VALUES (29, 2, 0, 190);
INSERT INTO static."ProductFares" VALUES (30, 2, 0, 190);
INSERT INTO static."ProductFares" VALUES (31, 2, 0, 190);
INSERT INTO static."ProductFares" VALUES (32, 2, 0, 210);
INSERT INTO static."ProductFares" VALUES (33, 2, 0, 210);
INSERT INTO static."ProductFares" VALUES (34, 2, 0, 210);
INSERT INTO static."ProductFares" VALUES (35, 2, 0, 210);
INSERT INTO static."ProductFares" VALUES (36, 2, 0, 210);
INSERT INTO static."ProductFares" VALUES (37, 2, 0, 210);
INSERT INTO static."ProductFares" VALUES (38, 2, 0, 210);
INSERT INTO static."ProductFares" VALUES (39, 2, 0, 210);
INSERT INTO static."ProductFares" VALUES (40, 2, 0, 210);
INSERT INTO static."ProductFares" VALUES (41, 2, 0, 210);
INSERT INTO static."ProductFares" VALUES (42, 2, 0, 210);
INSERT INTO static."ProductFares" VALUES (43, 2, 0, 210);
INSERT INTO static."ProductFares" VALUES (44, 2, 0, 260);
INSERT INTO static."ProductFares" VALUES (45, 2, 0, 260);
INSERT INTO static."ProductFares" VALUES (46, 2, 0, 260);
INSERT INTO static."ProductFares" VALUES (47, 2, 0, 260);
INSERT INTO static."ProductFares" VALUES (48, 2, 0, 260);
INSERT INTO static."ProductFares" VALUES (49, 2, 0, 260);
INSERT INTO static."ProductFares" VALUES (50, 2, 0, 260);
INSERT INTO static."ProductFares" VALUES (51, 2, 0, 260);
INSERT INTO static."ProductFares" VALUES (52, 2, 0, 260);
INSERT INTO static."ProductFares" VALUES (53, 2, 0, 260);
INSERT INTO static."ProductFares" VALUES (54, 2, 0, 260);
INSERT INTO static."ProductFares" VALUES (55, 2, 0, 300);
INSERT INTO static."ProductFares" VALUES (56, 2, 0, 300);
INSERT INTO static."ProductFares" VALUES (57, 2, 0, 300);
INSERT INTO static."ProductFares" VALUES (58, 2, 0, 300);
INSERT INTO static."ProductFares" VALUES (59, 2, 0, 300);
INSERT INTO static."ProductFares" VALUES (60, 2, 0, 300);
INSERT INTO static."ProductFares" VALUES (61, 2, 0, 300);
INSERT INTO static."ProductFares" VALUES (62, 2, 0, 300);
INSERT INTO static."ProductFares" VALUES (63, 2, 0, 300);
INSERT INTO static."ProductFares" VALUES (64, 2, 0, 300);
INSERT INTO static."ProductFares" VALUES (65, 2, 0, 370);
INSERT INTO static."ProductFares" VALUES (66, 2, 0, 370);
INSERT INTO static."ProductFares" VALUES (67, 2, 0, 370);
INSERT INTO static."ProductFares" VALUES (68, 2, 0, 370);
INSERT INTO static."ProductFares" VALUES (69, 2, 0, 370);
INSERT INTO static."ProductFares" VALUES (70, 2, 0, 370);
INSERT INTO static."ProductFares" VALUES (71, 2, 0, 370);
INSERT INTO static."ProductFares" VALUES (72, 2, 0, 370);
INSERT INTO static."ProductFares" VALUES (73, 2, 0, 370);
INSERT INTO static."ProductFares" VALUES (74, 2, 0, 450);
INSERT INTO static."ProductFares" VALUES (75, 2, 0, 450);
INSERT INTO static."ProductFares" VALUES (76, 2, 0, 450);
INSERT INTO static."ProductFares" VALUES (77, 2, 0, 450);
INSERT INTO static."ProductFares" VALUES (78, 2, 0, 450);
INSERT INTO static."ProductFares" VALUES (79, 2, 0, 450);
INSERT INTO static."ProductFares" VALUES (80, 2, 0, 450);
INSERT INTO static."ProductFares" VALUES (81, 2, 0, 450);
INSERT INTO static."ProductFares" VALUES (82, 2, 0, 530);
INSERT INTO static."ProductFares" VALUES (83, 2, 0, 530);
INSERT INTO static."ProductFares" VALUES (84, 2, 0, 530);
INSERT INTO static."ProductFares" VALUES (85, 2, 0, 530);
INSERT INTO static."ProductFares" VALUES (86, 2, 0, 530);
INSERT INTO static."ProductFares" VALUES (87, 2, 0, 530);
INSERT INTO static."ProductFares" VALUES (88, 2, 0, 530);
INSERT INTO static."ProductFares" VALUES (89, 2, 0, 530);
INSERT INTO static."ProductFares" VALUES (90, 2, 0, 530);
INSERT INTO static."ProductFares" VALUES (91, 2, 0, 530);
INSERT INTO static."ProductFares" VALUES (92, 2, 0, 530);
INSERT INTO static."ProductFares" VALUES (93, 2, 0, 530);
INSERT INTO static."ProductFares" VALUES (94, 2, 0, 530);
INSERT INTO static."ProductFares" VALUES (95, 2, 0, 530);
INSERT INTO static."ProductFares" VALUES (96, 2, 0, 530);
INSERT INTO static."ProductFares" VALUES (97, 2, 0, 530);
INSERT INTO static."ProductFares" VALUES (98, 2, 0, 530);
INSERT INTO static."ProductFares" VALUES (99, 2, 0, 530);
INSERT INTO static."ProductFares" VALUES (100, 2, 0, 530);
INSERT INTO static."ProductFares" VALUES (101, 2, 0, 530);
INSERT INTO static."ProductFares" VALUES (102, 2, 0, 530);
INSERT INTO static."ProductFares" VALUES (103, 2, 0, 530);
INSERT INTO static."ProductFares" VALUES (104, 2, 0, 530);
INSERT INTO static."ProductFares" VALUES (105, 2, 0, 530);
INSERT INTO static."ProductFares" VALUES (106, 2, 0, 530);
INSERT INTO static."ProductFares" VALUES (107, 2, 0, 530);
INSERT INTO static."ProductFares" VALUES (108, 2, 0, 530);
INSERT INTO static."ProductFares" VALUES (109, 2, 0, 530);
INSERT INTO static."ProductFares" VALUES (1, 3, 0, 265);
INSERT INTO static."ProductFares" VALUES (2, 3, 0, 450);
INSERT INTO static."ProductFares" VALUES (4, 3, 0, 530);
INSERT INTO static."ProductFares" VALUES (5, 3, 0, 165);
INSERT INTO static."ProductFares" VALUES (6, 3, 0, 140);
INSERT INTO static."ProductFares" VALUES (7, 3, 0, 140);
INSERT INTO static."ProductFares" VALUES (8, 3, 0, 140);
INSERT INTO static."ProductFares" VALUES (9, 3, 0, 140);
INSERT INTO static."ProductFares" VALUES (10, 3, 0, 140);
INSERT INTO static."ProductFares" VALUES (11, 3, 0, 140);
INSERT INTO static."ProductFares" VALUES (12, 3, 0, 140);
INSERT INTO static."ProductFares" VALUES (13, 3, 0, 140);
INSERT INTO static."ProductFares" VALUES (14, 3, 0, 140);
INSERT INTO static."ProductFares" VALUES (15, 3, 0, 140);
INSERT INTO static."ProductFares" VALUES (16, 3, 0, 140);
INSERT INTO static."ProductFares" VALUES (17, 3, 0, 140);
INSERT INTO static."ProductFares" VALUES (18, 3, 0, 140);
INSERT INTO static."ProductFares" VALUES (19, 3, 0, 190);
INSERT INTO static."ProductFares" VALUES (20, 3, 0, 190);
INSERT INTO static."ProductFares" VALUES (21, 3, 0, 190);
INSERT INTO static."ProductFares" VALUES (22, 3, 0, 190);
INSERT INTO static."ProductFares" VALUES (23, 3, 0, 190);
INSERT INTO static."ProductFares" VALUES (24, 3, 0, 190);
INSERT INTO static."ProductFares" VALUES (25, 3, 0, 190);
INSERT INTO static."ProductFares" VALUES (26, 3, 0, 190);
INSERT INTO static."ProductFares" VALUES (27, 3, 0, 190);
INSERT INTO static."ProductFares" VALUES (28, 3, 0, 190);
INSERT INTO static."ProductFares" VALUES (29, 3, 0, 190);
INSERT INTO static."ProductFares" VALUES (30, 3, 0, 190);
INSERT INTO static."ProductFares" VALUES (31, 3, 0, 190);
INSERT INTO static."ProductFares" VALUES (32, 3, 0, 210);
INSERT INTO static."ProductFares" VALUES (33, 3, 0, 210);
INSERT INTO static."ProductFares" VALUES (34, 3, 0, 210);
INSERT INTO static."ProductFares" VALUES (35, 3, 0, 210);
INSERT INTO static."ProductFares" VALUES (36, 3, 0, 210);
INSERT INTO static."ProductFares" VALUES (37, 3, 0, 210);
INSERT INTO static."ProductFares" VALUES (38, 3, 0, 210);
INSERT INTO static."ProductFares" VALUES (39, 3, 0, 210);
INSERT INTO static."ProductFares" VALUES (40, 3, 0, 210);
INSERT INTO static."ProductFares" VALUES (41, 3, 0, 210);
INSERT INTO static."ProductFares" VALUES (42, 3, 0, 210);
INSERT INTO static."ProductFares" VALUES (43, 3, 0, 210);
INSERT INTO static."ProductFares" VALUES (44, 3, 0, 260);
INSERT INTO static."ProductFares" VALUES (45, 3, 0, 260);
INSERT INTO static."ProductFares" VALUES (46, 3, 0, 260);
INSERT INTO static."ProductFares" VALUES (47, 3, 0, 260);
INSERT INTO static."ProductFares" VALUES (48, 3, 0, 260);
INSERT INTO static."ProductFares" VALUES (49, 3, 0, 260);
INSERT INTO static."ProductFares" VALUES (50, 3, 0, 260);
INSERT INTO static."ProductFares" VALUES (51, 3, 0, 260);
INSERT INTO static."ProductFares" VALUES (52, 3, 0, 260);
INSERT INTO static."ProductFares" VALUES (53, 3, 0, 260);
INSERT INTO static."ProductFares" VALUES (54, 3, 0, 260);
INSERT INTO static."ProductFares" VALUES (55, 3, 0, 300);
INSERT INTO static."ProductFares" VALUES (56, 3, 0, 300);
INSERT INTO static."ProductFares" VALUES (57, 3, 0, 300);
INSERT INTO static."ProductFares" VALUES (58, 3, 0, 300);
INSERT INTO static."ProductFares" VALUES (59, 3, 0, 300);
INSERT INTO static."ProductFares" VALUES (60, 3, 0, 300);
INSERT INTO static."ProductFares" VALUES (61, 3, 0, 300);
INSERT INTO static."ProductFares" VALUES (62, 3, 0, 300);
INSERT INTO static."ProductFares" VALUES (63, 3, 0, 300);
INSERT INTO static."ProductFares" VALUES (64, 3, 0, 300);
INSERT INTO static."ProductFares" VALUES (65, 3, 0, 370);
INSERT INTO static."ProductFares" VALUES (66, 3, 0, 370);
INSERT INTO static."ProductFares" VALUES (67, 3, 0, 370);
INSERT INTO static."ProductFares" VALUES (68, 3, 0, 370);
INSERT INTO static."ProductFares" VALUES (69, 3, 0, 370);
INSERT INTO static."ProductFares" VALUES (70, 3, 0, 370);
INSERT INTO static."ProductFares" VALUES (71, 3, 0, 370);
INSERT INTO static."ProductFares" VALUES (72, 3, 0, 370);
INSERT INTO static."ProductFares" VALUES (73, 3, 0, 370);
INSERT INTO static."ProductFares" VALUES (74, 3, 0, 450);
INSERT INTO static."ProductFares" VALUES (75, 3, 0, 450);
INSERT INTO static."ProductFares" VALUES (76, 3, 0, 450);
INSERT INTO static."ProductFares" VALUES (77, 3, 0, 450);
INSERT INTO static."ProductFares" VALUES (78, 3, 0, 450);
INSERT INTO static."ProductFares" VALUES (79, 3, 0, 450);
INSERT INTO static."ProductFares" VALUES (80, 3, 0, 450);
INSERT INTO static."ProductFares" VALUES (81, 3, 0, 450);
INSERT INTO static."ProductFares" VALUES (82, 3, 0, 530);
INSERT INTO static."ProductFares" VALUES (83, 3, 0, 530);
INSERT INTO static."ProductFares" VALUES (84, 3, 0, 530);
INSERT INTO static."ProductFares" VALUES (85, 3, 0, 530);
INSERT INTO static."ProductFares" VALUES (86, 3, 0, 530);
INSERT INTO static."ProductFares" VALUES (87, 3, 0, 530);
INSERT INTO static."ProductFares" VALUES (88, 3, 0, 530);
INSERT INTO static."ProductFares" VALUES (89, 3, 0, 530);
INSERT INTO static."ProductFares" VALUES (90, 3, 0, 530);
INSERT INTO static."ProductFares" VALUES (91, 3, 0, 530);
INSERT INTO static."ProductFares" VALUES (92, 3, 0, 530);
INSERT INTO static."ProductFares" VALUES (93, 3, 0, 530);
INSERT INTO static."ProductFares" VALUES (94, 3, 0, 530);
INSERT INTO static."ProductFares" VALUES (95, 3, 0, 530);
INSERT INTO static."ProductFares" VALUES (96, 3, 0, 530);
INSERT INTO static."ProductFares" VALUES (97, 3, 0, 530);
INSERT INTO static."ProductFares" VALUES (98, 3, 0, 530);
INSERT INTO static."ProductFares" VALUES (99, 3, 0, 530);
INSERT INTO static."ProductFares" VALUES (100, 3, 0, 530);
INSERT INTO static."ProductFares" VALUES (101, 3, 0, 530);
INSERT INTO static."ProductFares" VALUES (102, 3, 0, 530);
INSERT INTO static."ProductFares" VALUES (103, 3, 0, 530);
INSERT INTO static."ProductFares" VALUES (104, 3, 0, 530);
INSERT INTO static."ProductFares" VALUES (105, 3, 0, 530);
INSERT INTO static."ProductFares" VALUES (106, 3, 0, 530);
INSERT INTO static."ProductFares" VALUES (107, 3, 0, 530);
INSERT INTO static."ProductFares" VALUES (108, 3, 0, 530);
INSERT INTO static."ProductFares" VALUES (109, 3, 0, 530);
INSERT INTO static."ProductFares" VALUES (1, 4, 0, 265);
INSERT INTO static."ProductFares" VALUES (2, 4, 0, 450);
INSERT INTO static."ProductFares" VALUES (4, 4, 0, 530);
INSERT INTO static."ProductFares" VALUES (5, 4, 0, 165);
INSERT INTO static."ProductFares" VALUES (6, 4, 0, 140);
INSERT INTO static."ProductFares" VALUES (7, 4, 0, 140);
INSERT INTO static."ProductFares" VALUES (8, 4, 0, 140);
INSERT INTO static."ProductFares" VALUES (9, 4, 0, 140);
INSERT INTO static."ProductFares" VALUES (10, 4, 0, 140);
INSERT INTO static."ProductFares" VALUES (11, 4, 0, 140);
INSERT INTO static."ProductFares" VALUES (12, 4, 0, 140);
INSERT INTO static."ProductFares" VALUES (13, 4, 0, 140);
INSERT INTO static."ProductFares" VALUES (14, 4, 0, 140);
INSERT INTO static."ProductFares" VALUES (15, 4, 0, 140);
INSERT INTO static."ProductFares" VALUES (16, 4, 0, 140);
INSERT INTO static."ProductFares" VALUES (17, 4, 0, 140);
INSERT INTO static."ProductFares" VALUES (18, 4, 0, 140);
INSERT INTO static."ProductFares" VALUES (19, 4, 0, 190);
INSERT INTO static."ProductFares" VALUES (20, 4, 0, 190);
INSERT INTO static."ProductFares" VALUES (21, 4, 0, 190);
INSERT INTO static."ProductFares" VALUES (22, 4, 0, 190);
INSERT INTO static."ProductFares" VALUES (23, 4, 0, 190);
INSERT INTO static."ProductFares" VALUES (24, 4, 0, 190);
INSERT INTO static."ProductFares" VALUES (25, 4, 0, 190);
INSERT INTO static."ProductFares" VALUES (26, 4, 0, 190);
INSERT INTO static."ProductFares" VALUES (27, 4, 0, 190);
INSERT INTO static."ProductFares" VALUES (28, 4, 0, 190);
INSERT INTO static."ProductFares" VALUES (29, 4, 0, 190);
INSERT INTO static."ProductFares" VALUES (30, 4, 0, 190);
INSERT INTO static."ProductFares" VALUES (31, 4, 0, 190);
INSERT INTO static."ProductFares" VALUES (32, 4, 0, 210);
INSERT INTO static."ProductFares" VALUES (33, 4, 0, 210);
INSERT INTO static."ProductFares" VALUES (34, 4, 0, 210);
INSERT INTO static."ProductFares" VALUES (35, 4, 0, 210);
INSERT INTO static."ProductFares" VALUES (36, 4, 0, 210);
INSERT INTO static."ProductFares" VALUES (37, 4, 0, 210);
INSERT INTO static."ProductFares" VALUES (38, 4, 0, 210);
INSERT INTO static."ProductFares" VALUES (39, 4, 0, 210);
INSERT INTO static."ProductFares" VALUES (40, 4, 0, 210);
INSERT INTO static."ProductFares" VALUES (41, 4, 0, 210);
INSERT INTO static."ProductFares" VALUES (42, 4, 0, 210);
INSERT INTO static."ProductFares" VALUES (43, 4, 0, 210);
INSERT INTO static."ProductFares" VALUES (44, 4, 0, 260);
INSERT INTO static."ProductFares" VALUES (45, 4, 0, 260);
INSERT INTO static."ProductFares" VALUES (46, 4, 0, 260);
INSERT INTO static."ProductFares" VALUES (47, 4, 0, 260);
INSERT INTO static."ProductFares" VALUES (48, 4, 0, 260);
INSERT INTO static."ProductFares" VALUES (49, 4, 0, 260);
INSERT INTO static."ProductFares" VALUES (50, 4, 0, 260);
INSERT INTO static."ProductFares" VALUES (51, 4, 0, 260);
INSERT INTO static."ProductFares" VALUES (52, 4, 0, 260);
INSERT INTO static."ProductFares" VALUES (53, 4, 0, 260);
INSERT INTO static."ProductFares" VALUES (54, 4, 0, 260);
INSERT INTO static."ProductFares" VALUES (55, 4, 0, 300);
INSERT INTO static."ProductFares" VALUES (56, 4, 0, 300);
INSERT INTO static."ProductFares" VALUES (57, 4, 0, 300);
INSERT INTO static."ProductFares" VALUES (58, 4, 0, 300);
INSERT INTO static."ProductFares" VALUES (59, 4, 0, 300);
INSERT INTO static."ProductFares" VALUES (60, 4, 0, 300);
INSERT INTO static."ProductFares" VALUES (61, 4, 0, 300);
INSERT INTO static."ProductFares" VALUES (62, 4, 0, 300);
INSERT INTO static."ProductFares" VALUES (63, 4, 0, 300);
INSERT INTO static."ProductFares" VALUES (64, 4, 0, 300);
INSERT INTO static."ProductFares" VALUES (65, 4, 0, 370);
INSERT INTO static."ProductFares" VALUES (66, 4, 0, 370);
INSERT INTO static."ProductFares" VALUES (67, 4, 0, 370);
INSERT INTO static."ProductFares" VALUES (68, 4, 0, 370);
INSERT INTO static."ProductFares" VALUES (69, 4, 0, 370);
INSERT INTO static."ProductFares" VALUES (70, 4, 0, 370);
INSERT INTO static."ProductFares" VALUES (71, 4, 0, 370);
INSERT INTO static."ProductFares" VALUES (72, 4, 0, 370);
INSERT INTO static."ProductFares" VALUES (73, 4, 0, 370);
INSERT INTO static."ProductFares" VALUES (74, 4, 0, 450);
INSERT INTO static."ProductFares" VALUES (75, 4, 0, 450);
INSERT INTO static."ProductFares" VALUES (76, 4, 0, 450);
INSERT INTO static."ProductFares" VALUES (77, 4, 0, 450);
INSERT INTO static."ProductFares" VALUES (78, 4, 0, 450);
INSERT INTO static."ProductFares" VALUES (79, 4, 0, 450);
INSERT INTO static."ProductFares" VALUES (80, 4, 0, 450);
INSERT INTO static."ProductFares" VALUES (81, 4, 0, 450);
INSERT INTO static."ProductFares" VALUES (82, 4, 0, 530);
INSERT INTO static."ProductFares" VALUES (83, 4, 0, 530);
INSERT INTO static."ProductFares" VALUES (84, 4, 0, 530);
INSERT INTO static."ProductFares" VALUES (85, 4, 0, 530);
INSERT INTO static."ProductFares" VALUES (86, 4, 0, 530);
INSERT INTO static."ProductFares" VALUES (87, 4, 0, 530);
INSERT INTO static."ProductFares" VALUES (88, 4, 0, 530);
INSERT INTO static."ProductFares" VALUES (89, 4, 0, 530);
INSERT INTO static."ProductFares" VALUES (90, 4, 0, 530);
INSERT INTO static."ProductFares" VALUES (91, 4, 0, 530);
INSERT INTO static."ProductFares" VALUES (92, 4, 0, 530);
INSERT INTO static."ProductFares" VALUES (93, 4, 0, 530);
INSERT INTO static."ProductFares" VALUES (94, 4, 0, 530);
INSERT INTO static."ProductFares" VALUES (95, 4, 0, 530);
INSERT INTO static."ProductFares" VALUES (96, 4, 0, 530);
INSERT INTO static."ProductFares" VALUES (97, 4, 0, 530);
INSERT INTO static."ProductFares" VALUES (98, 4, 0, 530);
INSERT INTO static."ProductFares" VALUES (99, 4, 0, 530);
INSERT INTO static."ProductFares" VALUES (100, 4, 0, 530);
INSERT INTO static."ProductFares" VALUES (101, 4, 0, 530);
INSERT INTO static."ProductFares" VALUES (102, 4, 0, 530);
INSERT INTO static."ProductFares" VALUES (103, 4, 0, 530);
INSERT INTO static."ProductFares" VALUES (104, 4, 0, 530);
INSERT INTO static."ProductFares" VALUES (105, 4, 0, 530);
INSERT INTO static."ProductFares" VALUES (106, 4, 0, 530);
INSERT INTO static."ProductFares" VALUES (107, 4, 0, 530);
INSERT INTO static."ProductFares" VALUES (108, 4, 0, 530);
INSERT INTO static."ProductFares" VALUES (109, 4, 0, 530);
INSERT INTO static."ProductFares" VALUES (1, 5, 0, 265);
INSERT INTO static."ProductFares" VALUES (2, 5, 0, 450);
INSERT INTO static."ProductFares" VALUES (4, 5, 0, 530);
INSERT INTO static."ProductFares" VALUES (5, 5, 0, 165);
INSERT INTO static."ProductFares" VALUES (6, 5, 0, 140);
INSERT INTO static."ProductFares" VALUES (7, 5, 0, 140);
INSERT INTO static."ProductFares" VALUES (8, 5, 0, 140);
INSERT INTO static."ProductFares" VALUES (9, 5, 0, 140);
INSERT INTO static."ProductFares" VALUES (10, 5, 0, 140);
INSERT INTO static."ProductFares" VALUES (11, 5, 0, 140);
INSERT INTO static."ProductFares" VALUES (12, 5, 0, 140);
INSERT INTO static."ProductFares" VALUES (13, 5, 0, 140);
INSERT INTO static."ProductFares" VALUES (14, 5, 0, 140);
INSERT INTO static."ProductFares" VALUES (15, 5, 0, 140);
INSERT INTO static."ProductFares" VALUES (16, 5, 0, 140);
INSERT INTO static."ProductFares" VALUES (17, 5, 0, 140);
INSERT INTO static."ProductFares" VALUES (18, 5, 0, 140);
INSERT INTO static."ProductFares" VALUES (19, 5, 0, 190);
INSERT INTO static."ProductFares" VALUES (20, 5, 0, 190);
INSERT INTO static."ProductFares" VALUES (21, 5, 0, 190);
INSERT INTO static."ProductFares" VALUES (22, 5, 0, 190);
INSERT INTO static."ProductFares" VALUES (23, 5, 0, 190);
INSERT INTO static."ProductFares" VALUES (24, 5, 0, 190);
INSERT INTO static."ProductFares" VALUES (25, 5, 0, 190);
INSERT INTO static."ProductFares" VALUES (26, 5, 0, 190);
INSERT INTO static."ProductFares" VALUES (27, 5, 0, 190);
INSERT INTO static."ProductFares" VALUES (28, 5, 0, 190);
INSERT INTO static."ProductFares" VALUES (29, 5, 0, 190);
INSERT INTO static."ProductFares" VALUES (30, 5, 0, 190);
INSERT INTO static."ProductFares" VALUES (31, 5, 0, 190);
INSERT INTO static."ProductFares" VALUES (32, 5, 0, 210);
INSERT INTO static."ProductFares" VALUES (33, 5, 0, 210);
INSERT INTO static."ProductFares" VALUES (34, 5, 0, 210);
INSERT INTO static."ProductFares" VALUES (35, 5, 0, 210);
INSERT INTO static."ProductFares" VALUES (36, 5, 0, 210);
INSERT INTO static."ProductFares" VALUES (37, 5, 0, 210);
INSERT INTO static."ProductFares" VALUES (38, 5, 0, 210);
INSERT INTO static."ProductFares" VALUES (39, 5, 0, 210);
INSERT INTO static."ProductFares" VALUES (40, 5, 0, 210);
INSERT INTO static."ProductFares" VALUES (41, 5, 0, 210);
INSERT INTO static."ProductFares" VALUES (42, 5, 0, 210);
INSERT INTO static."ProductFares" VALUES (43, 5, 0, 210);
INSERT INTO static."ProductFares" VALUES (44, 5, 0, 260);
INSERT INTO static."ProductFares" VALUES (45, 5, 0, 260);
INSERT INTO static."ProductFares" VALUES (46, 5, 0, 260);
INSERT INTO static."ProductFares" VALUES (47, 5, 0, 260);
INSERT INTO static."ProductFares" VALUES (48, 5, 0, 260);
INSERT INTO static."ProductFares" VALUES (49, 5, 0, 260);
INSERT INTO static."ProductFares" VALUES (50, 5, 0, 260);
INSERT INTO static."ProductFares" VALUES (51, 5, 0, 260);
INSERT INTO static."ProductFares" VALUES (52, 5, 0, 260);
INSERT INTO static."ProductFares" VALUES (53, 5, 0, 260);
INSERT INTO static."ProductFares" VALUES (54, 5, 0, 260);
INSERT INTO static."ProductFares" VALUES (55, 5, 0, 300);
INSERT INTO static."ProductFares" VALUES (56, 5, 0, 300);
INSERT INTO static."ProductFares" VALUES (57, 5, 0, 300);
INSERT INTO static."ProductFares" VALUES (58, 5, 0, 300);
INSERT INTO static."ProductFares" VALUES (59, 5, 0, 300);
INSERT INTO static."ProductFares" VALUES (60, 5, 0, 300);
INSERT INTO static."ProductFares" VALUES (61, 5, 0, 300);
INSERT INTO static."ProductFares" VALUES (62, 5, 0, 300);
INSERT INTO static."ProductFares" VALUES (63, 5, 0, 300);
INSERT INTO static."ProductFares" VALUES (64, 5, 0, 300);
INSERT INTO static."ProductFares" VALUES (65, 5, 0, 370);
INSERT INTO static."ProductFares" VALUES (66, 5, 0, 370);
INSERT INTO static."ProductFares" VALUES (67, 5, 0, 370);
INSERT INTO static."ProductFares" VALUES (68, 5, 0, 370);
INSERT INTO static."ProductFares" VALUES (69, 5, 0, 370);
INSERT INTO static."ProductFares" VALUES (70, 5, 0, 370);
INSERT INTO static."ProductFares" VALUES (71, 5, 0, 370);
INSERT INTO static."ProductFares" VALUES (72, 5, 0, 370);
INSERT INTO static."ProductFares" VALUES (73, 5, 0, 370);
INSERT INTO static."ProductFares" VALUES (74, 5, 0, 450);
INSERT INTO static."ProductFares" VALUES (75, 5, 0, 450);
INSERT INTO static."ProductFares" VALUES (76, 5, 0, 450);
INSERT INTO static."ProductFares" VALUES (77, 5, 0, 450);
INSERT INTO static."ProductFares" VALUES (78, 5, 0, 450);
INSERT INTO static."ProductFares" VALUES (79, 5, 0, 450);
INSERT INTO static."ProductFares" VALUES (80, 5, 0, 450);
INSERT INTO static."ProductFares" VALUES (81, 5, 0, 450);
INSERT INTO static."ProductFares" VALUES (82, 5, 0, 530);
INSERT INTO static."ProductFares" VALUES (83, 5, 0, 530);
INSERT INTO static."ProductFares" VALUES (84, 5, 0, 530);
INSERT INTO static."ProductFares" VALUES (85, 5, 0, 530);
INSERT INTO static."ProductFares" VALUES (86, 5, 0, 530);
INSERT INTO static."ProductFares" VALUES (87, 5, 0, 530);
INSERT INTO static."ProductFares" VALUES (88, 5, 0, 530);
INSERT INTO static."ProductFares" VALUES (89, 5, 0, 530);
INSERT INTO static."ProductFares" VALUES (90, 5, 0, 530);
INSERT INTO static."ProductFares" VALUES (91, 5, 0, 530);
INSERT INTO static."ProductFares" VALUES (92, 5, 0, 530);
INSERT INTO static."ProductFares" VALUES (93, 5, 0, 530);
INSERT INTO static."ProductFares" VALUES (94, 5, 0, 530);
INSERT INTO static."ProductFares" VALUES (95, 5, 0, 530);
INSERT INTO static."ProductFares" VALUES (96, 5, 0, 530);
INSERT INTO static."ProductFares" VALUES (97, 5, 0, 530);
INSERT INTO static."ProductFares" VALUES (98, 5, 0, 530);
INSERT INTO static."ProductFares" VALUES (99, 5, 0, 530);
INSERT INTO static."ProductFares" VALUES (100, 5, 0, 530);
INSERT INTO static."ProductFares" VALUES (101, 5, 0, 530);
INSERT INTO static."ProductFares" VALUES (102, 5, 0, 530);
INSERT INTO static."ProductFares" VALUES (103, 5, 0, 530);
INSERT INTO static."ProductFares" VALUES (104, 5, 0, 530);
INSERT INTO static."ProductFares" VALUES (105, 5, 0, 530);
INSERT INTO static."ProductFares" VALUES (106, 5, 0, 530);
INSERT INTO static."ProductFares" VALUES (107, 5, 0, 530);
INSERT INTO static."ProductFares" VALUES (108, 5, 0, 530);
INSERT INTO static."ProductFares" VALUES (109, 5, 0, 530);
INSERT INTO static."ProductFares" VALUES (1, 6, 0, 265);
INSERT INTO static."ProductFares" VALUES (2, 6, 0, 450);
INSERT INTO static."ProductFares" VALUES (4, 6, 0, 530);
INSERT INTO static."ProductFares" VALUES (5, 6, 0, 165);
INSERT INTO static."ProductFares" VALUES (6, 6, 0, 140);
INSERT INTO static."ProductFares" VALUES (7, 6, 0, 140);
INSERT INTO static."ProductFares" VALUES (8, 6, 0, 140);
INSERT INTO static."ProductFares" VALUES (9, 6, 0, 140);
INSERT INTO static."ProductFares" VALUES (10, 6, 0, 140);
INSERT INTO static."ProductFares" VALUES (11, 6, 0, 140);
INSERT INTO static."ProductFares" VALUES (12, 6, 0, 140);
INSERT INTO static."ProductFares" VALUES (13, 6, 0, 140);
INSERT INTO static."ProductFares" VALUES (14, 6, 0, 140);
INSERT INTO static."ProductFares" VALUES (15, 6, 0, 140);
INSERT INTO static."ProductFares" VALUES (16, 6, 0, 140);
INSERT INTO static."ProductFares" VALUES (17, 6, 0, 140);
INSERT INTO static."ProductFares" VALUES (18, 6, 0, 140);
INSERT INTO static."ProductFares" VALUES (19, 6, 0, 190);
INSERT INTO static."ProductFares" VALUES (20, 6, 0, 190);
INSERT INTO static."ProductFares" VALUES (21, 6, 0, 190);
INSERT INTO static."ProductFares" VALUES (22, 6, 0, 190);
INSERT INTO static."ProductFares" VALUES (23, 6, 0, 190);
INSERT INTO static."ProductFares" VALUES (24, 6, 0, 190);
INSERT INTO static."ProductFares" VALUES (25, 6, 0, 190);
INSERT INTO static."ProductFares" VALUES (26, 6, 0, 190);
INSERT INTO static."ProductFares" VALUES (27, 6, 0, 190);
INSERT INTO static."ProductFares" VALUES (28, 6, 0, 190);
INSERT INTO static."ProductFares" VALUES (29, 6, 0, 190);
INSERT INTO static."ProductFares" VALUES (30, 6, 0, 190);
INSERT INTO static."ProductFares" VALUES (31, 6, 0, 190);
INSERT INTO static."ProductFares" VALUES (32, 6, 0, 210);
INSERT INTO static."ProductFares" VALUES (33, 6, 0, 210);
INSERT INTO static."ProductFares" VALUES (34, 6, 0, 210);
INSERT INTO static."ProductFares" VALUES (35, 6, 0, 210);
INSERT INTO static."ProductFares" VALUES (36, 6, 0, 210);
INSERT INTO static."ProductFares" VALUES (37, 6, 0, 210);
INSERT INTO static."ProductFares" VALUES (38, 6, 0, 210);
INSERT INTO static."ProductFares" VALUES (39, 6, 0, 210);
INSERT INTO static."ProductFares" VALUES (40, 6, 0, 210);
INSERT INTO static."ProductFares" VALUES (41, 6, 0, 210);
INSERT INTO static."ProductFares" VALUES (42, 6, 0, 210);
INSERT INTO static."ProductFares" VALUES (43, 6, 0, 210);
INSERT INTO static."ProductFares" VALUES (44, 6, 0, 260);
INSERT INTO static."ProductFares" VALUES (45, 6, 0, 260);
INSERT INTO static."ProductFares" VALUES (46, 6, 0, 260);
INSERT INTO static."ProductFares" VALUES (47, 6, 0, 260);
INSERT INTO static."ProductFares" VALUES (48, 6, 0, 260);
INSERT INTO static."ProductFares" VALUES (49, 6, 0, 260);
INSERT INTO static."ProductFares" VALUES (50, 6, 0, 260);
INSERT INTO static."ProductFares" VALUES (51, 6, 0, 260);
INSERT INTO static."ProductFares" VALUES (52, 6, 0, 260);
INSERT INTO static."ProductFares" VALUES (53, 6, 0, 260);
INSERT INTO static."ProductFares" VALUES (54, 6, 0, 260);
INSERT INTO static."ProductFares" VALUES (55, 6, 0, 300);
INSERT INTO static."ProductFares" VALUES (56, 6, 0, 300);
INSERT INTO static."ProductFares" VALUES (57, 6, 0, 300);
INSERT INTO static."ProductFares" VALUES (58, 6, 0, 300);
INSERT INTO static."ProductFares" VALUES (59, 6, 0, 300);
INSERT INTO static."ProductFares" VALUES (60, 6, 0, 300);
INSERT INTO static."ProductFares" VALUES (61, 6, 0, 300);
INSERT INTO static."ProductFares" VALUES (62, 6, 0, 300);
INSERT INTO static."ProductFares" VALUES (63, 6, 0, 300);
INSERT INTO static."ProductFares" VALUES (64, 6, 0, 300);
INSERT INTO static."ProductFares" VALUES (65, 6, 0, 370);
INSERT INTO static."ProductFares" VALUES (66, 6, 0, 370);
INSERT INTO static."ProductFares" VALUES (67, 6, 0, 370);
INSERT INTO static."ProductFares" VALUES (68, 6, 0, 370);
INSERT INTO static."ProductFares" VALUES (69, 6, 0, 370);
INSERT INTO static."ProductFares" VALUES (70, 6, 0, 370);
INSERT INTO static."ProductFares" VALUES (71, 6, 0, 370);
INSERT INTO static."ProductFares" VALUES (72, 6, 0, 370);
INSERT INTO static."ProductFares" VALUES (73, 6, 0, 370);
INSERT INTO static."ProductFares" VALUES (74, 6, 0, 450);
INSERT INTO static."ProductFares" VALUES (75, 6, 0, 450);
INSERT INTO static."ProductFares" VALUES (76, 6, 0, 450);
INSERT INTO static."ProductFares" VALUES (77, 6, 0, 450);
INSERT INTO static."ProductFares" VALUES (78, 6, 0, 450);
INSERT INTO static."ProductFares" VALUES (79, 6, 0, 450);
INSERT INTO static."ProductFares" VALUES (80, 6, 0, 450);
INSERT INTO static."ProductFares" VALUES (81, 6, 0, 450);
INSERT INTO static."ProductFares" VALUES (82, 6, 0, 530);
INSERT INTO static."ProductFares" VALUES (83, 6, 0, 530);
INSERT INTO static."ProductFares" VALUES (84, 6, 0, 530);
INSERT INTO static."ProductFares" VALUES (85, 6, 0, 530);
INSERT INTO static."ProductFares" VALUES (86, 6, 0, 530);
INSERT INTO static."ProductFares" VALUES (87, 6, 0, 530);
INSERT INTO static."ProductFares" VALUES (88, 6, 0, 530);
INSERT INTO static."ProductFares" VALUES (89, 6, 0, 530);
INSERT INTO static."ProductFares" VALUES (90, 6, 0, 530);
INSERT INTO static."ProductFares" VALUES (91, 6, 0, 530);
INSERT INTO static."ProductFares" VALUES (92, 6, 0, 530);
INSERT INTO static."ProductFares" VALUES (93, 6, 0, 530);
INSERT INTO static."ProductFares" VALUES (94, 6, 0, 530);
INSERT INTO static."ProductFares" VALUES (95, 6, 0, 530);
INSERT INTO static."ProductFares" VALUES (96, 6, 0, 530);
INSERT INTO static."ProductFares" VALUES (97, 6, 0, 530);
INSERT INTO static."ProductFares" VALUES (98, 6, 0, 530);
INSERT INTO static."ProductFares" VALUES (99, 6, 0, 530);
INSERT INTO static."ProductFares" VALUES (100, 6, 0, 530);
INSERT INTO static."ProductFares" VALUES (101, 6, 0, 530);
INSERT INTO static."ProductFares" VALUES (102, 6, 0, 530);
INSERT INTO static."ProductFares" VALUES (103, 6, 0, 530);
INSERT INTO static."ProductFares" VALUES (104, 6, 0, 530);
INSERT INTO static."ProductFares" VALUES (105, 6, 0, 530);
INSERT INTO static."ProductFares" VALUES (106, 6, 0, 530);
INSERT INTO static."ProductFares" VALUES (107, 6, 0, 530);
INSERT INTO static."ProductFares" VALUES (108, 6, 0, 530);
INSERT INTO static."ProductFares" VALUES (109, 6, 0, 530);
INSERT INTO static."ProductFares" VALUES (1, 3, 1, 0);
INSERT INTO static."ProductFares" VALUES (5, 3, 1, 0);
INSERT INTO static."ProductFares" VALUES (6, 3, 1, 0);
INSERT INTO static."ProductFares" VALUES (7, 3, 1, 0);
INSERT INTO static."ProductFares" VALUES (8, 3, 1, 0);
INSERT INTO static."ProductFares" VALUES (9, 3, 1, 0);
INSERT INTO static."ProductFares" VALUES (10, 3, 1, 0);
INSERT INTO static."ProductFares" VALUES (11, 3, 1, 0);
INSERT INTO static."ProductFares" VALUES (12, 3, 1, 0);
INSERT INTO static."ProductFares" VALUES (13, 3, 1, 0);
INSERT INTO static."ProductFares" VALUES (14, 3, 1, 0);
INSERT INTO static."ProductFares" VALUES (15, 3, 1, 0);
INSERT INTO static."ProductFares" VALUES (16, 3, 1, 0);
INSERT INTO static."ProductFares" VALUES (17, 3, 1, 0);
INSERT INTO static."ProductFares" VALUES (18, 3, 1, 0);
INSERT INTO static."ProductFares" VALUES (19, 3, 1, 0);
INSERT INTO static."ProductFares" VALUES (20, 3, 1, 0);
INSERT INTO static."ProductFares" VALUES (21, 3, 1, 0);
INSERT INTO static."ProductFares" VALUES (22, 3, 1, 0);
INSERT INTO static."ProductFares" VALUES (23, 3, 1, 0);
INSERT INTO static."ProductFares" VALUES (24, 3, 1, 0);
INSERT INTO static."ProductFares" VALUES (25, 3, 1, 0);
INSERT INTO static."ProductFares" VALUES (26, 3, 1, 0);
INSERT INTO static."ProductFares" VALUES (27, 3, 1, 0);
INSERT INTO static."ProductFares" VALUES (28, 3, 1, 0);
INSERT INTO static."ProductFares" VALUES (29, 3, 1, 0);
INSERT INTO static."ProductFares" VALUES (30, 3, 1, 0);
INSERT INTO static."ProductFares" VALUES (31, 3, 1, 0);
INSERT INTO static."ProductFares" VALUES (1, 4, 1, 0);
INSERT INTO static."ProductFares" VALUES (5, 4, 1, 0);
INSERT INTO static."ProductFares" VALUES (6, 4, 1, 0);
INSERT INTO static."ProductFares" VALUES (7, 4, 1, 0);
INSERT INTO static."ProductFares" VALUES (8, 4, 1, 0);
INSERT INTO static."ProductFares" VALUES (9, 4, 1, 0);
INSERT INTO static."ProductFares" VALUES (10, 4, 1, 0);
INSERT INTO static."ProductFares" VALUES (11, 4, 1, 0);
INSERT INTO static."ProductFares" VALUES (12, 4, 1, 0);
INSERT INTO static."ProductFares" VALUES (13, 4, 1, 0);
INSERT INTO static."ProductFares" VALUES (14, 4, 1, 0);
INSERT INTO static."ProductFares" VALUES (15, 4, 1, 0);
INSERT INTO static."ProductFares" VALUES (16, 4, 1, 0);
INSERT INTO static."ProductFares" VALUES (17, 4, 1, 0);
INSERT INTO static."ProductFares" VALUES (18, 4, 1, 0);
INSERT INTO static."ProductFares" VALUES (19, 4, 1, 0);
INSERT INTO static."ProductFares" VALUES (20, 4, 1, 0);
INSERT INTO static."ProductFares" VALUES (21, 4, 1, 0);
INSERT INTO static."ProductFares" VALUES (22, 4, 1, 0);
INSERT INTO static."ProductFares" VALUES (23, 4, 1, 0);
INSERT INTO static."ProductFares" VALUES (24, 4, 1, 0);
INSERT INTO static."ProductFares" VALUES (25, 4, 1, 0);
INSERT INTO static."ProductFares" VALUES (26, 4, 1, 0);
INSERT INTO static."ProductFares" VALUES (27, 4, 1, 0);
INSERT INTO static."ProductFares" VALUES (28, 4, 1, 0);
INSERT INTO static."ProductFares" VALUES (29, 4, 1, 0);
INSERT INTO static."ProductFares" VALUES (30, 4, 1, 0);
INSERT INTO static."ProductFares" VALUES (31, 4, 1, 0);
INSERT INTO static."ProductFares" VALUES (1, 5, 1, 0);
INSERT INTO static."ProductFares" VALUES (5, 5, 1, 0);
INSERT INTO static."ProductFares" VALUES (6, 5, 1, 0);
INSERT INTO static."ProductFares" VALUES (7, 5, 1, 0);
INSERT INTO static."ProductFares" VALUES (8, 5, 1, 0);
INSERT INTO static."ProductFares" VALUES (9, 5, 1, 0);
INSERT INTO static."ProductFares" VALUES (10, 5, 1, 0);
INSERT INTO static."ProductFares" VALUES (11, 5, 1, 0);
INSERT INTO static."ProductFares" VALUES (12, 5, 1, 0);
INSERT INTO static."ProductFares" VALUES (13, 5, 1, 0);
INSERT INTO static."ProductFares" VALUES (14, 5, 1, 0);
INSERT INTO static."ProductFares" VALUES (15, 5, 1, 0);
INSERT INTO static."ProductFares" VALUES (16, 5, 1, 0);
INSERT INTO static."ProductFares" VALUES (17, 5, 1, 0);
INSERT INTO static."ProductFares" VALUES (18, 5, 1, 0);
INSERT INTO static."ProductFares" VALUES (19, 5, 1, 0);
INSERT INTO static."ProductFares" VALUES (20, 5, 1, 0);
INSERT INTO static."ProductFares" VALUES (21, 5, 1, 0);
INSERT INTO static."ProductFares" VALUES (22, 5, 1, 0);
INSERT INTO static."ProductFares" VALUES (23, 5, 1, 0);
INSERT INTO static."ProductFares" VALUES (24, 5, 1, 0);
INSERT INTO static."ProductFares" VALUES (25, 5, 1, 0);
INSERT INTO static."ProductFares" VALUES (26, 5, 1, 0);
INSERT INTO static."ProductFares" VALUES (27, 5, 1, 0);
INSERT INTO static."ProductFares" VALUES (28, 5, 1, 0);
INSERT INTO static."ProductFares" VALUES (29, 5, 1, 0);
INSERT INTO static."ProductFares" VALUES (30, 5, 1, 0);
INSERT INTO static."ProductFares" VALUES (31, 5, 1, 0);


--
-- TOC entry 3156 (class 0 OID 16510)
-- Dependencies: 206
-- Data for Name: Products; Type: TABLE DATA; Schema: static; Owner: postgres
--

INSERT INTO static."Products" VALUES (0, 'None', 0, 0, 120);
INSERT INTO static."Products" VALUES (1, 'Zone 1+2', 1, 2, 120);
INSERT INTO static."Products" VALUES (2, 'Zone 1+2+3', 1, 3, 150);
INSERT INTO static."Products" VALUES (3, 'Zone 1/2 overlap', 0, 0, 120);
INSERT INTO static."Products" VALUES (4, 'Zones 1-15', 1, 15, 270);
INSERT INTO static."Products" VALUES (5, 'Zone 2', 2, 2, 120);
INSERT INTO static."Products" VALUES (6, 'Zone 3', 3, 3, 120);
INSERT INTO static."Products" VALUES (7, 'Zone 4', 4, 4, 120);
INSERT INTO static."Products" VALUES (8, 'Zone 5', 5, 5, 120);
INSERT INTO static."Products" VALUES (9, 'Zone 6', 6, 6, 120);
INSERT INTO static."Products" VALUES (10, 'Zone 7', 7, 7, 120);
INSERT INTO static."Products" VALUES (11, 'Zone 8', 8, 8, 120);
INSERT INTO static."Products" VALUES (12, 'Zone 9', 9, 9, 120);
INSERT INTO static."Products" VALUES (13, 'Zone 10', 10, 10, 120);
INSERT INTO static."Products" VALUES (14, 'Zone 11', 11, 11, 120);
INSERT INTO static."Products" VALUES (15, 'Zone 12', 12, 12, 120);
INSERT INTO static."Products" VALUES (16, 'Zone 13', 13, 13, 120);
INSERT INTO static."Products" VALUES (17, 'Zone 14', 14, 14, 120);
INSERT INTO static."Products" VALUES (18, 'Zone 15', 15, 15, 120);
INSERT INTO static."Products" VALUES (19, 'Zones 2-3', 2, 3, 120);
INSERT INTO static."Products" VALUES (20, 'Zones 3-4', 3, 4, 120);
INSERT INTO static."Products" VALUES (21, 'Zones 4-5', 4, 5, 120);
INSERT INTO static."Products" VALUES (22, 'Zones 5-6', 5, 6, 120);
INSERT INTO static."Products" VALUES (23, 'Zones 6-7', 6, 7, 120);
INSERT INTO static."Products" VALUES (24, 'Zones 7-8', 7, 8, 120);
INSERT INTO static."Products" VALUES (25, 'Zones 8-9', 8, 9, 120);
INSERT INTO static."Products" VALUES (26, 'Zones 9-10', 9, 10, 120);
INSERT INTO static."Products" VALUES (27, 'Zones 10-11', 10, 11, 120);
INSERT INTO static."Products" VALUES (28, 'Zones 11-12', 11, 12, 120);
INSERT INTO static."Products" VALUES (29, 'Zones 12-13', 12, 13, 120);
INSERT INTO static."Products" VALUES (30, 'Zones 13-14', 13, 14, 120);
INSERT INTO static."Products" VALUES (31, 'Zones 14-15', 14, 15, 120);
INSERT INTO static."Products" VALUES (32, 'Zones 2-4', 2, 4, 150);
INSERT INTO static."Products" VALUES (33, 'Zones 3-5', 3, 5, 150);
INSERT INTO static."Products" VALUES (34, 'Zones 4-6', 4, 6, 150);
INSERT INTO static."Products" VALUES (35, 'Zones 5-7', 5, 7, 150);
INSERT INTO static."Products" VALUES (36, 'Zones 6-8', 6, 8, 150);
INSERT INTO static."Products" VALUES (37, 'Zones 7-9', 7, 9, 150);
INSERT INTO static."Products" VALUES (38, 'Zones 8-10', 8, 10, 150);
INSERT INTO static."Products" VALUES (39, 'Zones 9-11', 9, 11, 150);
INSERT INTO static."Products" VALUES (40, 'Zones 10-12', 10, 12, 150);
INSERT INTO static."Products" VALUES (41, 'Zones 11-13', 11, 13, 150);
INSERT INTO static."Products" VALUES (42, 'Zones 12-14', 12, 14, 150);
INSERT INTO static."Products" VALUES (43, 'Zones 13-15', 13, 15, 150);
INSERT INTO static."Products" VALUES (44, 'Zones 2-5', 2, 5, 150);
INSERT INTO static."Products" VALUES (45, 'Zones 3-6', 3, 6, 150);
INSERT INTO static."Products" VALUES (46, 'Zones 4-7', 4, 7, 150);
INSERT INTO static."Products" VALUES (47, 'Zones 5-8', 5, 8, 150);
INSERT INTO static."Products" VALUES (48, 'Zones 6-9', 6, 9, 150);
INSERT INTO static."Products" VALUES (49, 'Zones 7-10', 7, 10, 150);
INSERT INTO static."Products" VALUES (50, 'Zones 8-11', 8, 11, 150);
INSERT INTO static."Products" VALUES (51, 'Zones 9-12', 9, 12, 150);
INSERT INTO static."Products" VALUES (52, 'Zones 10-13', 10, 13, 150);
INSERT INTO static."Products" VALUES (53, 'Zones 11-14', 11, 14, 150);
INSERT INTO static."Products" VALUES (54, 'Zones 12-15', 12, 15, 150);
INSERT INTO static."Products" VALUES (55, 'Zones 2-6', 2, 6, 150);
INSERT INTO static."Products" VALUES (56, 'Zones 3-7', 3, 7, 150);
INSERT INTO static."Products" VALUES (57, 'Zones 4-8', 4, 8, 150);
INSERT INTO static."Products" VALUES (58, 'Zones 5-9', 5, 9, 150);
INSERT INTO static."Products" VALUES (59, 'Zones 6-10', 6, 10, 150);
INSERT INTO static."Products" VALUES (60, 'Zones 7-11', 7, 11, 150);
INSERT INTO static."Products" VALUES (61, 'Zones 8-12', 8, 12, 150);
INSERT INTO static."Products" VALUES (62, 'Zones 9-13', 9, 13, 150);
INSERT INTO static."Products" VALUES (63, 'Zones 10-14', 10, 14, 150);
INSERT INTO static."Products" VALUES (64, 'Zones 11-15', 11, 15, 150);
INSERT INTO static."Products" VALUES (65, 'Zones 2-7', 2, 7, 180);
INSERT INTO static."Products" VALUES (66, 'Zones 3-8', 3, 8, 180);
INSERT INTO static."Products" VALUES (67, 'Zones 4-9', 4, 9, 180);
INSERT INTO static."Products" VALUES (68, 'Zones 5-10', 5, 10, 180);
INSERT INTO static."Products" VALUES (69, 'Zones 6-11', 6, 11, 180);
INSERT INTO static."Products" VALUES (70, 'Zones 7-12', 7, 12, 180);
INSERT INTO static."Products" VALUES (71, 'Zones 8-13', 8, 13, 180);
INSERT INTO static."Products" VALUES (72, 'Zones 9-14', 9, 14, 180);
INSERT INTO static."Products" VALUES (73, 'Zones 10-15', 10, 15, 180);
INSERT INTO static."Products" VALUES (74, 'Zones 2-8', 2, 8, 180);
INSERT INTO static."Products" VALUES (75, 'Zones 3-9', 3, 9, 180);
INSERT INTO static."Products" VALUES (76, 'Zones 4-10', 4, 10, 180);
INSERT INTO static."Products" VALUES (77, 'Zones 5-11', 5, 11, 180);
INSERT INTO static."Products" VALUES (78, 'Zones 6-12', 6, 12, 180);
INSERT INTO static."Products" VALUES (79, 'Zones 7-13', 7, 13, 180);
INSERT INTO static."Products" VALUES (80, 'Zones 8-14', 8, 14, 180);
INSERT INTO static."Products" VALUES (81, 'Zones 9-15', 9, 15, 180);
INSERT INTO static."Products" VALUES (82, 'Zones 2-9', 2, 9, 180);
INSERT INTO static."Products" VALUES (83, 'Zones 3-10', 3, 10, 180);
INSERT INTO static."Products" VALUES (84, 'Zones 4-11', 4, 11, 180);
INSERT INTO static."Products" VALUES (85, 'Zones 5-12', 5, 12, 180);
INSERT INTO static."Products" VALUES (86, 'Zones 6-13', 6, 13, 180);
INSERT INTO static."Products" VALUES (87, 'Zones 7-14', 7, 14, 180);
INSERT INTO static."Products" VALUES (88, 'Zones 8-15', 8, 15, 180);
INSERT INTO static."Products" VALUES (89, 'Zones 2-10', 2, 10, 210);
INSERT INTO static."Products" VALUES (90, 'Zones 3-11', 3, 11, 210);
INSERT INTO static."Products" VALUES (91, 'Zones 4-12', 4, 12, 210);
INSERT INTO static."Products" VALUES (92, 'Zones 5-13', 5, 13, 210);
INSERT INTO static."Products" VALUES (93, 'Zones 6-14', 6, 14, 210);
INSERT INTO static."Products" VALUES (94, 'Zones 7-15', 7, 15, 210);
INSERT INTO static."Products" VALUES (95, 'Zones 2-11', 2, 11, 210);
INSERT INTO static."Products" VALUES (96, 'Zones 3-12', 3, 12, 210);
INSERT INTO static."Products" VALUES (97, 'Zones 4-13', 4, 13, 210);
INSERT INTO static."Products" VALUES (98, 'Zones 5-14', 5, 14, 210);
INSERT INTO static."Products" VALUES (99, 'Zones 6-15', 6, 15, 210);
INSERT INTO static."Products" VALUES (100, 'Zones 2-12', 2, 12, 210);
INSERT INTO static."Products" VALUES (101, 'Zones 3-13', 3, 13, 210);
INSERT INTO static."Products" VALUES (102, 'Zones 4-14', 4, 14, 210);
INSERT INTO static."Products" VALUES (103, 'Zones 5-15', 5, 15, 210);
INSERT INTO static."Products" VALUES (104, 'Zones 2-13', 2, 13, 240);
INSERT INTO static."Products" VALUES (105, 'Zones 3-14', 3, 14, 240);
INSERT INTO static."Products" VALUES (106, 'Zones 4-15', 4, 15, 240);
INSERT INTO static."Products" VALUES (107, 'Zones 2-14', 2, 14, 240);
INSERT INTO static."Products" VALUES (108, 'Zones 3-15', 3, 15, 240);
INSERT INTO static."Products" VALUES (109, 'Zones 2-15', 2, 15, 240);


--
-- TOC entry 3158 (class 0 OID 16520)
-- Dependencies: 208
-- Data for Name: SpecialDates; Type: TABLE DATA; Schema: static; Owner: postgres
--

INSERT INTO static."SpecialDates" VALUES ('2024-01-01', '2024-01-01', 1, 'New Year''s Day');
INSERT INTO static."SpecialDates" VALUES ('2024-01-26', '2024-01-26', 1, 'Australia Day');
INSERT INTO static."SpecialDates" VALUES ('2024-03-11', '2024-03-11', 1, 'Labour Day');
INSERT INTO static."SpecialDates" VALUES ('2024-03-29', '2024-03-29', 1, 'Good Friday');
INSERT INTO static."SpecialDates" VALUES ('2024-03-30', '2024-03-30', 1, 'Saturday before Easter Sunday');
INSERT INTO static."SpecialDates" VALUES ('2024-03-31', '2024-03-31', 1, 'Easter Sunday');
INSERT INTO static."SpecialDates" VALUES ('2024-04-01', '2024-04-01', 1, 'Easter Monday');
INSERT INTO static."SpecialDates" VALUES ('2024-04-25', '2024-04-25', 9, 'ANZAC Day');
INSERT INTO static."SpecialDates" VALUES ('2024-06-10', '2024-06-10', 1, 'King''s Birthday');
INSERT INTO static."SpecialDates" VALUES ('2024-09-27', '2024-09-27', 1, 'Friday before the AFL Grand Final');
INSERT INTO static."SpecialDates" VALUES ('2024-11-05', '2024-11-05', 1, 'Melbourne Cup');
INSERT INTO static."SpecialDates" VALUES ('2024-12-25', '2024-12-25', 1, 'Christmas Day');
INSERT INTO static."SpecialDates" VALUES ('2024-12-26', '2024-12-26', 1, 'Boxing Day');
INSERT INTO static."SpecialDates" VALUES ('2024-02-19', '2024-02-19', 8, 'Bombing of Darwin Day');
INSERT INTO static."SpecialDates" VALUES ('2024-05-08', '2024-05-08', 8, 'Victory in Europe (VE) Day');
INSERT INTO static."SpecialDates" VALUES ('2024-07-27', '2024-07-27', 8, 'Korean Veterans'' Day');
INSERT INTO static."SpecialDates" VALUES ('2024-08-15', '2024-08-15', 8, 'Victory in the Pacific (VP) Day');
INSERT INTO static."SpecialDates" VALUES ('2024-08-18', '2024-08-18', 8, 'Vietnam Veterans'' Day');
INSERT INTO static."SpecialDates" VALUES ('2024-08-31', '2024-08-31', 8, 'Malaya and Borneo Veterans'' Day');
INSERT INTO static."SpecialDates" VALUES ('2024-09-03', '2024-09-03', 8, 'Merchant Navy Day');
INSERT INTO static."SpecialDates" VALUES ('2024-09-04', '2024-09-04', 8, 'Battle for Australia Day');
INSERT INTO static."SpecialDates" VALUES ('2024-09-14', '2024-09-14', 8, 'National Peacekeepers'' Day');
INSERT INTO static."SpecialDates" VALUES ('2024-11-11', '2024-11-11', 8, 'Remembrance Day');
INSERT INTO static."SpecialDates" VALUES ('2024-10-13', '2024-10-19', 2, 'National Carers'' Week');
INSERT INTO static."SpecialDates" VALUES ('2024-10-13', '2024-10-20', 8, 'Veterans'' Health Week');
INSERT INTO static."SpecialDates" VALUES ('2024-10-01', '2024-10-31', 4, 'Victorian Seniors Festival');


--
-- TOC entry 3157 (class 0 OID 16515)
-- Dependencies: 207
-- Data for Name: TransactionTypes; Type: TABLE DATA; Schema: static; Owner: postgres
--

INSERT INTO static."TransactionTypes" VALUES (0, 'Touch on');
INSERT INTO static."TransactionTypes" VALUES (1, 'Touch off');
INSERT INTO static."TransactionTypes" VALUES (2, 'Touch off and on');
INSERT INTO static."TransactionTypes" VALUES (3, 'Failed touch off');
INSERT INTO static."TransactionTypes" VALUES (4, 'Top up');
INSERT INTO static."TransactionTypes" VALUES (5, 'Pass purchase');


--
-- TOC entry 3159 (class 0 OID 16525)
-- Dependencies: 209
-- Data for Name: TransportModes; Type: TABLE DATA; Schema: static; Owner: postgres
--

INSERT INTO static."TransportModes" VALUES (0, 'None');
INSERT INTO static."TransportModes" VALUES (1, 'Bus');
INSERT INTO static."TransportModes" VALUES (2, 'Tram');
INSERT INTO static."TransportModes" VALUES (3, 'Train');


--
-- TOC entry 3190 (class 0 OID 0)
-- Dependencies: 210
-- Name: Locations_id_seq; Type: SEQUENCE SET; Schema: static; Owner: postgres
--

SELECT pg_catalog.setval('static."Locations_id_seq"', 222, true);


--
-- TOC entry 3011 (class 2606 OID 16648)
-- Name: Passes Passes_pkey; Type: CONSTRAINT; Schema: dynamic; Owner: postgres
--

ALTER TABLE ONLY dynamic."Passes"
    ADD CONSTRAINT "Passes_pkey" PRIMARY KEY ("transactionID");


--
-- TOC entry 3009 (class 2606 OID 16638)
-- Name: PhysicalTickets PhysicalTickets_pkey; Type: CONSTRAINT; Schema: dynamic; Owner: postgres
--

ALTER TABLE ONLY dynamic."PhysicalTickets"
    ADD CONSTRAINT "PhysicalTickets_pkey" PRIMARY KEY (id);


--
-- TOC entry 3005 (class 2606 OID 16589)
-- Name: Tickets Tickets_pkey; Type: CONSTRAINT; Schema: dynamic; Owner: postgres
--

ALTER TABLE ONLY dynamic."Tickets"
    ADD CONSTRAINT "Tickets_pkey" PRIMARY KEY (id);


--
-- TOC entry 3007 (class 2606 OID 16611)
-- Name: Transactions Transactions_pkey; Type: CONSTRAINT; Schema: dynamic; Owner: postgres
--

ALTER TABLE ONLY dynamic."Transactions"
    ADD CONSTRAINT "Transactions_pkey" PRIMARY KEY (id);


--
-- TOC entry 3003 (class 2606 OID 16572)
-- Name: DailyFareCaps DailyFareCaps_pkey; Type: CONSTRAINT; Schema: static; Owner: postgres
--

ALTER TABLE ONLY static."DailyFareCaps"
    ADD CONSTRAINT "DailyFareCaps_pkey" PRIMARY KEY ("dateCondition", "fareType");


--
-- TOC entry 2989 (class 2606 OID 16509)
-- Name: FareTypes FareTypes_pkey; Type: CONSTRAINT; Schema: static; Owner: postgres
--

ALTER TABLE ONLY static."FareTypes"
    ADD CONSTRAINT "FareTypes_pkey" PRIMARY KEY (type);


--
-- TOC entry 2999 (class 2606 OID 16537)
-- Name: Locations Locations_pkey; Type: CONSTRAINT; Schema: static; Owner: postgres
--

ALTER TABLE ONLY static."Locations"
    ADD CONSTRAINT "Locations_pkey" PRIMARY KEY (id);


--
-- TOC entry 3001 (class 2606 OID 16557)
-- Name: ProductFares ProductFares_pkey; Type: CONSTRAINT; Schema: static; Owner: postgres
--

ALTER TABLE ONLY static."ProductFares"
    ADD CONSTRAINT "ProductFares_pkey" PRIMARY KEY ("productID", "fareType", "dateCondition");


--
-- TOC entry 2991 (class 2606 OID 16514)
-- Name: Products Products_pkey; Type: CONSTRAINT; Schema: static; Owner: postgres
--

ALTER TABLE ONLY static."Products"
    ADD CONSTRAINT "Products_pkey" PRIMARY KEY (id);


--
-- TOC entry 2995 (class 2606 OID 16524)
-- Name: SpecialDates SpecialDates_pkey; Type: CONSTRAINT; Schema: static; Owner: postgres
--

ALTER TABLE ONLY static."SpecialDates"
    ADD CONSTRAINT "SpecialDates_pkey" PRIMARY KEY ("from", "to");


--
-- TOC entry 2993 (class 2606 OID 16519)
-- Name: TransactionTypes TransactionTypes_pkey; Type: CONSTRAINT; Schema: static; Owner: postgres
--

ALTER TABLE ONLY static."TransactionTypes"
    ADD CONSTRAINT "TransactionTypes_pkey" PRIMARY KEY (type);


--
-- TOC entry 2997 (class 2606 OID 16529)
-- Name: TransportModes TransportModes_pkey; Type: CONSTRAINT; Schema: static; Owner: postgres
--

ALTER TABLE ONLY static."TransportModes"
    ADD CONSTRAINT "TransportModes_pkey" PRIMARY KEY (mode);


--
-- TOC entry 3028 (class 2606 OID 16659)
-- Name: Passes Passes_product_fkey; Type: FK CONSTRAINT; Schema: dynamic; Owner: postgres
--

ALTER TABLE ONLY dynamic."Passes"
    ADD CONSTRAINT "Passes_product_fkey" FOREIGN KEY (product) REFERENCES static."Products"(id);


--
-- TOC entry 3027 (class 2606 OID 16654)
-- Name: Passes Passes_ticketID_fkey; Type: FK CONSTRAINT; Schema: dynamic; Owner: postgres
--

ALTER TABLE ONLY dynamic."Passes"
    ADD CONSTRAINT "Passes_ticketID_fkey" FOREIGN KEY ("ticketID") REFERENCES dynamic."Tickets"(id);


--
-- TOC entry 3026 (class 2606 OID 16649)
-- Name: Passes Passes_transactionID_fkey; Type: FK CONSTRAINT; Schema: dynamic; Owner: postgres
--

ALTER TABLE ONLY dynamic."Passes"
    ADD CONSTRAINT "Passes_transactionID_fkey" FOREIGN KEY ("transactionID") REFERENCES dynamic."Transactions"(id);


--
-- TOC entry 3025 (class 2606 OID 16639)
-- Name: PhysicalTickets PhysicalTickets_ticketID_fkey; Type: FK CONSTRAINT; Schema: dynamic; Owner: postgres
--

ALTER TABLE ONLY dynamic."PhysicalTickets"
    ADD CONSTRAINT "PhysicalTickets_ticketID_fkey" FOREIGN KEY ("ticketID") REFERENCES dynamic."Tickets"(id);


--
-- TOC entry 3019 (class 2606 OID 16595)
-- Name: Tickets Tickets_currentProduct_fkey; Type: FK CONSTRAINT; Schema: dynamic; Owner: postgres
--

ALTER TABLE ONLY dynamic."Tickets"
    ADD CONSTRAINT "Tickets_currentProduct_fkey" FOREIGN KEY ("currentProduct") REFERENCES static."Products"(id);


--
-- TOC entry 3018 (class 2606 OID 16590)
-- Name: Tickets Tickets_fareType_fkey; Type: FK CONSTRAINT; Schema: dynamic; Owner: postgres
--

ALTER TABLE ONLY dynamic."Tickets"
    ADD CONSTRAINT "Tickets_fareType_fkey" FOREIGN KEY ("fareType") REFERENCES static."FareTypes"(type);


--
-- TOC entry 3020 (class 2606 OID 16600)
-- Name: Tickets Tickets_touchedOn_fkey; Type: FK CONSTRAINT; Schema: dynamic; Owner: postgres
--

ALTER TABLE ONLY dynamic."Tickets"
    ADD CONSTRAINT "Tickets_touchedOn_fkey" FOREIGN KEY ("touchedOn") REFERENCES static."Products"(id);


--
-- TOC entry 3023 (class 2606 OID 16622)
-- Name: Transactions Transactions_location_fkey; Type: FK CONSTRAINT; Schema: dynamic; Owner: postgres
--

ALTER TABLE ONLY dynamic."Transactions"
    ADD CONSTRAINT "Transactions_location_fkey" FOREIGN KEY (location) REFERENCES static."Locations"(id);


--
-- TOC entry 3024 (class 2606 OID 16627)
-- Name: Transactions Transactions_product_fkey; Type: FK CONSTRAINT; Schema: dynamic; Owner: postgres
--

ALTER TABLE ONLY dynamic."Transactions"
    ADD CONSTRAINT "Transactions_product_fkey" FOREIGN KEY (product) REFERENCES static."Products"(id);


--
-- TOC entry 3021 (class 2606 OID 16612)
-- Name: Transactions Transactions_ticketID_fkey; Type: FK CONSTRAINT; Schema: dynamic; Owner: postgres
--

ALTER TABLE ONLY dynamic."Transactions"
    ADD CONSTRAINT "Transactions_ticketID_fkey" FOREIGN KEY ("ticketID") REFERENCES dynamic."Tickets"(id);


--
-- TOC entry 3022 (class 2606 OID 16617)
-- Name: Transactions Transactions_type_fkey; Type: FK CONSTRAINT; Schema: dynamic; Owner: postgres
--

ALTER TABLE ONLY dynamic."Transactions"
    ADD CONSTRAINT "Transactions_type_fkey" FOREIGN KEY (type) REFERENCES static."TransactionTypes"(type);


--
-- TOC entry 3017 (class 2606 OID 16573)
-- Name: DailyFareCaps DailyFareCaps_fareType_fkey; Type: FK CONSTRAINT; Schema: static; Owner: postgres
--

ALTER TABLE ONLY static."DailyFareCaps"
    ADD CONSTRAINT "DailyFareCaps_fareType_fkey" FOREIGN KEY ("fareType") REFERENCES static."FareTypes"(type);


--
-- TOC entry 3014 (class 2606 OID 16548)
-- Name: Locations Locations_defaultProduct_fkey; Type: FK CONSTRAINT; Schema: static; Owner: postgres
--

ALTER TABLE ONLY static."Locations"
    ADD CONSTRAINT "Locations_defaultProduct_fkey" FOREIGN KEY ("defaultProduct") REFERENCES static."Products"(id);


--
-- TOC entry 3013 (class 2606 OID 16543)
-- Name: Locations Locations_minProduct_fkey; Type: FK CONSTRAINT; Schema: static; Owner: postgres
--

ALTER TABLE ONLY static."Locations"
    ADD CONSTRAINT "Locations_minProduct_fkey" FOREIGN KEY ("minProduct") REFERENCES static."Products"(id);


--
-- TOC entry 3012 (class 2606 OID 16538)
-- Name: Locations Locations_mode_fkey; Type: FK CONSTRAINT; Schema: static; Owner: postgres
--

ALTER TABLE ONLY static."Locations"
    ADD CONSTRAINT "Locations_mode_fkey" FOREIGN KEY (mode) REFERENCES static."TransportModes"(mode);


--
-- TOC entry 3016 (class 2606 OID 16563)
-- Name: ProductFares ProductFares_fareType_fkey; Type: FK CONSTRAINT; Schema: static; Owner: postgres
--

ALTER TABLE ONLY static."ProductFares"
    ADD CONSTRAINT "ProductFares_fareType_fkey" FOREIGN KEY ("fareType") REFERENCES static."FareTypes"(type);


--
-- TOC entry 3015 (class 2606 OID 16558)
-- Name: ProductFares ProductFares_productID_fkey; Type: FK CONSTRAINT; Schema: static; Owner: postgres
--

ALTER TABLE ONLY static."ProductFares"
    ADD CONSTRAINT "ProductFares_productID_fkey" FOREIGN KEY ("productID") REFERENCES static."Products"(id);


--
-- TOC entry 3174 (class 0 OID 0)
-- Dependencies: 8
-- Name: SCHEMA dynamic; Type: ACL; Schema: -; Owner: dynamic
--

GRANT USAGE ON SCHEMA dynamic TO static;


--
-- TOC entry 3175 (class 0 OID 0)
-- Dependencies: 10
-- Name: SCHEMA static; Type: ACL; Schema: -; Owner: static
--

GRANT USAGE ON SCHEMA static TO dynamic;


--
-- TOC entry 3176 (class 0 OID 0)
-- Dependencies: 217
-- Name: TABLE "Passes"; Type: ACL; Schema: dynamic; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRUNCATE,UPDATE ON TABLE dynamic."Passes" TO dynamic;
GRANT SELECT ON TABLE dynamic."Passes" TO static;


--
-- TOC entry 3177 (class 0 OID 0)
-- Dependencies: 216
-- Name: TABLE "PhysicalTickets"; Type: ACL; Schema: dynamic; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRUNCATE,UPDATE ON TABLE dynamic."PhysicalTickets" TO dynamic;
GRANT SELECT ON TABLE dynamic."PhysicalTickets" TO static;


--
-- TOC entry 3178 (class 0 OID 0)
-- Dependencies: 214
-- Name: TABLE "Tickets"; Type: ACL; Schema: dynamic; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRUNCATE,UPDATE ON TABLE dynamic."Tickets" TO dynamic;
GRANT SELECT ON TABLE dynamic."Tickets" TO static;


--
-- TOC entry 3179 (class 0 OID 0)
-- Dependencies: 215
-- Name: TABLE "Transactions"; Type: ACL; Schema: dynamic; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRUNCATE,UPDATE ON TABLE dynamic."Transactions" TO dynamic;
GRANT SELECT ON TABLE dynamic."Transactions" TO static;


--
-- TOC entry 3180 (class 0 OID 0)
-- Dependencies: 213
-- Name: TABLE "DailyFareCaps"; Type: ACL; Schema: static; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRUNCATE,UPDATE ON TABLE static."DailyFareCaps" TO static;
GRANT SELECT ON TABLE static."DailyFareCaps" TO dynamic;


--
-- TOC entry 3181 (class 0 OID 0)
-- Dependencies: 205
-- Name: TABLE "FareTypes"; Type: ACL; Schema: static; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRUNCATE,UPDATE ON TABLE static."FareTypes" TO static;
GRANT SELECT ON TABLE static."FareTypes" TO dynamic;


--
-- TOC entry 3182 (class 0 OID 0)
-- Dependencies: 211
-- Name: TABLE "Locations"; Type: ACL; Schema: static; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRUNCATE,UPDATE ON TABLE static."Locations" TO static;
GRANT SELECT ON TABLE static."Locations" TO dynamic;


--
-- TOC entry 3184 (class 0 OID 0)
-- Dependencies: 210
-- Name: SEQUENCE "Locations_id_seq"; Type: ACL; Schema: static; Owner: postgres
--

GRANT USAGE ON SEQUENCE static."Locations_id_seq" TO static;


--
-- TOC entry 3185 (class 0 OID 0)
-- Dependencies: 212
-- Name: TABLE "ProductFares"; Type: ACL; Schema: static; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRUNCATE,UPDATE ON TABLE static."ProductFares" TO static;
GRANT SELECT ON TABLE static."ProductFares" TO dynamic;


--
-- TOC entry 3186 (class 0 OID 0)
-- Dependencies: 206
-- Name: TABLE "Products"; Type: ACL; Schema: static; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRUNCATE,UPDATE ON TABLE static."Products" TO static;
GRANT SELECT ON TABLE static."Products" TO dynamic;


--
-- TOC entry 3187 (class 0 OID 0)
-- Dependencies: 208
-- Name: TABLE "SpecialDates"; Type: ACL; Schema: static; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRUNCATE,UPDATE ON TABLE static."SpecialDates" TO static;
GRANT SELECT ON TABLE static."SpecialDates" TO dynamic;


--
-- TOC entry 3188 (class 0 OID 0)
-- Dependencies: 207
-- Name: TABLE "TransactionTypes"; Type: ACL; Schema: static; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRUNCATE,UPDATE ON TABLE static."TransactionTypes" TO static;
GRANT SELECT ON TABLE static."TransactionTypes" TO dynamic;


--
-- TOC entry 3189 (class 0 OID 0)
-- Dependencies: 209
-- Name: TABLE "TransportModes"; Type: ACL; Schema: static; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRUNCATE,UPDATE ON TABLE static."TransportModes" TO static;
GRANT SELECT ON TABLE static."TransportModes" TO dynamic;


-- Completed on 2024-09-19 13:26:17 UTC

--
-- PostgreSQL database dump complete
--

