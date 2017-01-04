DROP FUNCTION calc_tendex;

CREATE OR REPLACE FUNCTION calc_tendex(id IN VARCHAR2, nbaYear IN NUMBER, team IN VARCHAR2)
  RETURN NUMBER AS
  tendex Real;
  BEGIN
    SELECT (POINTS + REBOUNDS + ASSISTS + STEALS + BLOCKS - TURNOVERS - FOULS - (FGATTEMPTED - FGMADE)
            - (FTATTEMPTED - FTMADE) / 2) / MINUTES
    INTO tendex
    FROM PLAYERS_TEAMS pl
    WHERE pl.PLAYERID = id AND pl.YEAR = nbaYear AND pl.TEAMID = team;
    RETURN tendex;
    EXCEPTION
    WHEN TOO_MANY_ROWS
    THEN RETURN -1;
    WHEN NO_DATA_FOUND
    THEN RETURN 0;
    WHEN OTHERS
    THEN raise_application_error(
      -20011, 'Unknown Exception in calc_tendex Function');
  END;
  /

ALTER TABLE PLAYERS_TEAMS
  ADD PRIMARY KEY (PLAYERID, TEAMID, YEAR);

DECLARE

  id     VARCHAR2(26);
  year   NUMBER(6);
  team   VARCHAR2(4);
  result NUMBER(6,4);

BEGIN
  id := 'brezepr01';
  year := 2008;
  team := 'CHA';
  result := calc_tendex(id, year, team);
  dbms_output.put_line(' Player ' || id || ' in NBA Team ' || team || ' for the year ' || year || ' has ' || result);
END;
/
