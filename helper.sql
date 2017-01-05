CREATE OR REPLACE PROCEDURE orderPlayers AS
  nbaYear PLAYERS_TEAMS.YEAR%TYPE;
  plId    PLAYERS_TEAMS.PLAYERID%TYPE;
  teId    PLAYERS_TEAMS.TEAMID%TYPE;
  scorePl   PLAYERS_TEAMS.SCORE%TYPE;

  CURSOR myCurs IS
    SELECT
      PLAYERID,
      TEAMID,
      YEAR
    FROM PLAYERS_TEAMS
    FOR UPDATE;
  BEGIN
    OPEN myCurs;
    LOOP
      FETCH myCurs INTO plId, teId, nbaYear;
      EXIT WHEN myCurs%NOTFOUND;
      scorePl := calc_tendex(plId, nbaYear, teId);
      UPDATE PLAYERS_TEAMS
      SET SCORE = scorePl
      WHERE CURRENT OF myCurs;
    END LOOP;
    CLOSE myCurs;
  END;
/

BEGIN
  orderPlayers();
END;
/

SELECT SCORE
FROM PLAYERS_TEAMS;

SELECT
      PLAYERID,
      TEAMID,
      YEAR
    FROM PLAYERS_TEAMS;