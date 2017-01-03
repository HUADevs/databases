DROP TABLE duplicate_player_stats;
DROP PROCEDURE fix_duplicate_player_stats;
CREATE TABLE duplicate_player_stats AS SELECT *
                                       FROM PLAYERS_TEAMS
                                       WHERE 1=0; /*FALSE CONDITION IN ORDER TO AVOID COPYING DATA*/
                                      

CREATE OR REPLACE PROCEDURE fix_duplicate_player_stats AS

  CURSOR findDupl IS
    SELECT
      PLAYERID,
      TEAMID,
      YEAR,
      COUNT(*)
    FROM PLAYERS_TEAMS
    GROUP BY PLAYERID, TEAMID, YEAR
    HAVING count(*) > 1;

  dup_result findDupl%ROWTYPE;


  BEGIN
    OPEN findDupl;
    LOOP
      FETCH findDupl INTO dup_result;
      EXIT WHEN findDupl%NOTFOUND;
      INSERT INTO duplicate_player_stats SELECT *
                                         FROM PLAYERS_TEAMS
                                         WHERE PLAYERS_TEAMS.PLAYERID = dup_result.PLAYERID AND
                                               PLAYERS_TEAMS.TEAMID = dup_result.TEAMID AND
                                               PLAYERS_TEAMS.YEAR = dup_result.YEAR;
      DELETE FROM PLAYERS_TEAMS
      WHERE PLAYERS_TEAMS.PLAYERID = dup_result.PLAYERID AND PLAYERS_TEAMS.TEAMID = dup_result.TEAMID AND
            PLAYERS_TEAMS.YEAR = dup_result.YEAR;
      INSERT INTO PLAYERS_TEAMS SELECT
                                  PLAYERID,
                                  TEAMID,
                                  YEAR,
                                  LGID,
                                  SUM(
                                      POINTS),
                                  SUM(
                                      REBOUNDS),
                                  SUM(
                                      ASSISTS),
                                  SUM(
                                      STEALS),
                                  SUM(
                                      BLOCKS),
                                  SUM(
                                      TURNOVERS),
                                  SUM(
                                      MINUTES),
                                  SUM(
                                      FOULS),
                                  SUM(
                                      FGATTEMPTED),
                                  SUM(
                                      FGMADE),
                                  SUM(
                                      FTATTEMPTED),
                                  SUM(
                                      FTMADE)
                                FROM
                                  duplicate_player_stats
                                WHERE
                                  duplicate_player_stats.PLAYERID
                                  =
                                  dup_result.PLAYERID
                                  AND
                                  duplicate_player_stats.TEAMID
                                  =
                                  dup_result.TEAMID
                                  AND
                                  duplicate_player_stats.YEAR
                                  =
                                  dup_result.YEAR
                                GROUP BY PLAYERID, TEAMID, YEAR, LGID ;
    END LOOP;
    CLOSE findDupl;


  END;
/

