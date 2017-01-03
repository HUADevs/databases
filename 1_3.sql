CREATE PROCEDURE fix_team_divisions AS
  divs TEAMS.DIVISION%TYPE;

  CURSOR divCursor IS
    SELECT DIVISION FROM TEAMS FOR UPDATE;
  BEGIN
    OPEN divCursor;
    LOOP
      FETCH divCursor INTO divs;
      EXIT WHEN divCursor%NOTFOUND;
      IF divs='AT' OR divs='CD' OR divs='SE' THEN
        UPDATE TEAMS SET DIVISION = 'East' WHERE CURRENT OF divCursor;
      ELSIF divs='SW' OR divs='PC' OR divs='NW' THEN
        UPDATE TEAMS SET DIVISION = 'West' WHERE CURRENT OF divCursor;
      END IF;
    END LOOP;
    CLOSE divCursor;
  END;
/

BEGIN
    fix_team_divisions;
END;
/
