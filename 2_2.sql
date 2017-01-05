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
                                                                  XMLFOREST(PLAYERID AS "id",
                                                                            YEAR AS "year",
                                                                            CONFERENCE AS "division",
                                                                            POINTS AS "points",
                                                                            MINUTES AS "minutes"
                                                                  ))


                                                )
                                     ))
                       FROM ALLSTARS
                       WHERE YEAR = 2009 AND CONFERENCE IN ('East', 'West')
                       GROUP BY CONFERENCE)
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