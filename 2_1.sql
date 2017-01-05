CREATE OR REPLACE PROCEDURE get_top_players_xml(nbaYear IN NUMBER) AS
  qryctx DBMS_XMLGEN.ctxhandle;
  result XMLTYPE;
  BEGIN
    SELECT XMLELEMENT("nba", XMLATTRIBUTES ('topplayers' AS "dataset"),
                      (SELECT XMLAGG(XMLELEMENT("division", XMLATTRIBUTES (t.DIVISION AS "id"),
                                                XMLAGG(XMLELEMENT("player",
                                                                  XMLFOREST(pl.PLAYERID AS "id",
                                                                            pl.FIRSTNAME || ' ' ||
                                                                            pl.LASTNAME AS
                                                                            "name",
                                                                            pl.POSITION AS "position",
                                                                            pl_te.POINTS AS "points",
                                                                            pl_te.MINUTES AS "minutes",
                                                                            pl_te.SCORE AS "index",
                                                                            t.DIVISION AS "division"),
                                                                  XMLELEMENT("team",
                                                                             XMLFOREST(t.TEAMID AS
                                                                                       "teamId",
                                                                                       t.TEAMNAME AS
                                                                                       "name"))
                                                       ))
                                     ))
                       FROM PLAYERS pl
                         JOIN PLAYERS_TEAMS pl_te ON pl.PLAYERID = pl_te.PLAYERID
                         JOIN TEAMS t ON pl_te.TEAMID = t.TEAMID AND pl_te.YEAR = t.YEAR
                       WHERE t.YEAR = nbaYear AND t.DIVISION IN ('East', 'West')
                       GROUP BY t.DIVISION
                       ORDER BY pl_te.SCORE)
    )
    INTO RESULT
    FROM dual;
    /*dbms_output.put_line(result.getClobVal());*/

    INSERT INTO TEMP_CLOB_TAB VALUES (2, result);

  END;
  /

DECLARE
  num  NUMBER(6);
  year NUMBER(6);

BEGIN
  year := 2009;
  num := 10;
  get_top_players_xml(year);
END;
/