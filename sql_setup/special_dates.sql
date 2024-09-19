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

EXECUTE insert_special_date_n('2024-10-01', '2024-10-31', 4, 'Victorian Seniors Festival');