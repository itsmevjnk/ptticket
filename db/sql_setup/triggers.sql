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