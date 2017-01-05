SELECT XMLELEMENT("nba",
                  XMLATTRIBUTES ('allstars' AS "dataset"),
                  (SELECT XMLAGG(XMLELEMENT("division",
                                            XMLATTRIBUTES (CONFERENCE AS "id"),
                                            XMLAGG(XMLELEMENT("player",
                                                              XMLFOREST(PLAYERID AS "id",
                                                                        YEAR AS "year",
                                                                        CONFERENCE AS "conference",
                                                                        POINTS AS "points",
                                                                        MINUTES AS "minutes"
                                                              ))


                                            )
                                 ))
                   FROM ALLSTARS
                   WHERE YEAR = 2009 AND CONFERENCE IN ('East', 'West')
                   GROUP BY CONFERENCE
                  )
)
FROM dual;