DROP TABLE TEMP_CLOB_TAB;
CREATE TABLE TEMP_CLOB_TAB (
  id  NUMBER,
  xml XMLTYPE
);
CREATE OR REPLACE PROCEDURE get_allstar_players_xml AS
  result XMLTYPE;
  BEGIN
    SELECT XMLELEMENT("nba",
                      XMLATTRIBUTES ('allstars' AS "dataset"),
                      (SELECT XMLAGG(XMLELEMENT("division",
                                                XMLATTRIBUTES (CONFERENCE AS "id"),
                                                XMLAGG(XMLELEMENT("player",
                                                                  XMLFOREST(
                                                                            allstr.PLAYERID AS "id",
                                                                            pl.FIRSTNAME || ' ' ||
                                                                            pl.LASTNAME AS
                                                                            "name",
                                                                            pl.POSITION AS "position",
                                                                            allstr.POINTS AS "points",
                                                                            allstr.MINUTES AS "minutes",
                                                                            allstr.CONFERENCE AS "plDivision"),
                                                                  XMLELEMENT("team",
                                                                             XMLFOREST(t.TEAMID AS
                                                                                       "teamId",
                                                                                       t.TEAMNAME AS
                                                                                       "teamName")
                                                                  ))


                                                )
                                     ))
                       FROM ALLSTARS allstr JOIN PLAYERS pl ON allstr.PLAYERID = pl.PLAYERID JOIN PLAYERS_TEAMS plt ON pl.PLAYERID = plt.PLAYERID JOIN TEAMS t ON plt.TEAMID = t.TEAMID AND plt.YEAR = t.YEAR
                       WHERE allstr.YEAR = 2009 AND allstr.CONFERENCE IN ('East', 'West')
                       GROUP BY allstr.CONFERENCE)
    )
    INTO result
    FROM dual;

    INSERT INTO TEMP_CLOB_TAB VALUES (2,result);
  END;
/

BEGIN
  get_allstar_players_xml();
END;
/

SELECT * FROM TEMP_CLOB_TAB;
