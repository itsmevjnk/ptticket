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
