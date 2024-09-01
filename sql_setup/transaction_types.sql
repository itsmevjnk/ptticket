PREPARE insert_transaction_type(int, varchar(24)) AS INSERT INTO "static"."TransactionTypes" VALUES ($1, $2);

EXECUTE insert_transaction_type(0, 'Touch on');
EXECUTE insert_transaction_type(1, 'Touch off');
EXECUTE insert_transaction_type(2, 'Touch off and on');
EXECUTE insert_transaction_type(3, 'Failed touch off');
EXECUTE insert_transaction_type(4, 'Top up');