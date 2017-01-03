DROP FUNCTION calc_tendex;

CREATE OR REPLACE FUNCTION calc_tendex(id IN VARCHAR2, year IN NUMBER, team IN VARCHAR2)
  RETURN NUMBER IS
  tendex NUMBER(5, 4);
  BEGIN
    SELECT (POINTS + REBOUNDS + ASSISTS + STEALS + BLOCKS - TURNOVERS - FOULS - (FGATTEMPTED - FGMADE)
            - (FTATTEMPTED - FTMADE) / 2) / MINUTES
    INTO tendex
    FROM PLAYERS_TEAMS pl
    WHERE pl.PLAYERID = id AND pl.YEAR = year AND pl.TEAMID = team;
    RETURN tendex;
  END;
  /

ALTER TABLE PLAYERS_TEAMS
  ADD PRIMARY KEY (PLAYERID, TEAMID, YEAR);

DECLARE
  id     VARCHAR2(26);
  year   NUMBER(6);
  team   VARCHAR2(4);
  result REAL;

BEGIN
  id := 'brezepr01';
  year := '2009';
  team := 'CHA';
  result := calc_tendex(id, year, team);
  dbms_output.put_line(' Player ' || id || ' in NBA Team ' || team || ' for the year ' || year || ' has ' || result);
END;
/