--1_1--
DROP TABLE ALLSTARS;
DROP TABLE PLAYERS_TEAMS;
DROP TABLE TEAMS;
DROP TABLE PLAYERS;


CREATE TABLE ALLSTARS AS SELECT *
                         FROM XSALES.ALLSTARS;


CREATE TABLE PLAYERS AS SELECT *
                        FROM XSALES.PLAYERS;


CREATE TABLE PLAYERS_TEAMS AS SELECT *
                              FROM XSALES.PLAYERS_TEAMS;


CREATE TABLE TEAMS AS SELECT *
                      FROM XSALES.TEAMS;


ALTER TABLE PLAYERS
  ADD PRIMARY KEY (PLAYERID);

ALTER TABLE ALLSTARS
  ADD PRIMARY KEY (YEAR, PLAYERID);

ALTER TABLE TEAMS
  ADD PRIMARY KEY (TEAMID, YEAR);

ALTER TABLE ALLSTARS
  ADD CONSTRAINT allstarsforeign FOREIGN KEY (PLAYERID) REFERENCES PLAYERS (PLAYERID) ON DELETE CASCADE;

ALTER TABLE PLAYERS_TEAMS
  ADD CONSTRAINT play_team_1 FOREIGN KEY (PLAYERID) REFERENCES PLAYERS (PLAYERID) ON DELETE CASCADE;

ALTER TABLE PLAYERS_TEAMS
  ADD CONSTRAINT play_team_2 FOREIGN KEY (TEAMID, YEAR) REFERENCES TEAMS (TEAMID, YEAR) ON DELETE CASCADE;

--1_2--
DROP PROCEDURE fix_player_metrics;

CREATE OR REPLACE PROCEDURE fix_player_metrics AS
  cm_height PLAYERS.HEIGHT%TYPE;
  kg_weight PLAYERS.WEIGHT%TYPE;

  CURSOR mCursor IS
    SELECT
      HEIGHT,
      WEIGHT
    FROM PLAYERS
    FOR UPDATE;
  BEGIN
    OPEN mCursor;
    LOOP
      FETCH mCursor INTO cm_height, kg_weight;
      EXIT WHEN mCursor%NOTFOUND;
      cm_height := cm_height * 2.54;
      kg_weight := kg_weight * 0.45;
      UPDATE PLAYERS
      SET HEIGHT = cm_height, WEIGHT = kg_weight
      WHERE CURRENT OF mCursor;
    END LOOP;
    CLOSE mCursor;
  END;
/

BEGIN
  FIX_PLAYER_METRICS();
END;
/

--1_3--
DROP PROCEDURE fix_team_divisions;
CREATE OR REPLACE PROCEDURE fix_team_divisions AS
  divs TEAMS.DIVISION%TYPE;

  CURSOR divCursor IS
    SELECT DIVISION
    FROM TEAMS
    FOR UPDATE;
  BEGIN
    OPEN divCursor;
    LOOP
      FETCH divCursor INTO divs;
      EXIT WHEN divCursor%NOTFOUND;
      IF divs = 'AT' OR divs = 'CD' OR divs = 'SE'
      THEN
        UPDATE TEAMS
        SET DIVISION = 'East'
        WHERE CURRENT OF divCursor;
      ELSIF divs = 'SW' OR divs = 'PC' OR divs = 'NW'
        THEN
          UPDATE TEAMS
          SET DIVISION = 'West'
          WHERE CURRENT OF divCursor;
      END IF;
    END LOOP;
    CLOSE divCursor;
  END;
/

BEGIN
  fix_team_divisions;
END;
/

--1_4--
ALTER TABLE PLAYERS_TEAMS
  ADD score NUMBER(6, 4);

DROP TABLE duplicate_player_stats;
DROP PROCEDURE fix_duplicate_player_stats;
CREATE TABLE duplicate_player_stats AS SELECT *
                                       FROM PLAYERS_TEAMS
                                       WHERE 1 = 0;
/*FALSE CONDITION IN ORDER TO AVOID COPYING DATA*/


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
      INSERT INTO PLAYERS_TEAMS (PLAYERID, TEAMID, YEAR, LGID, POINTS, REBOUNDS, ASSISTS, STEALS, BLOCKS, TURNOVERS, MINUTES, FOULS,
                                 FGATTEMPTED, FGMADE, FTATTEMPTED, FTMADE)
        SELECT
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
        GROUP BY PLAYERID, TEAMID, YEAR, LGID;
    END LOOP;
    CLOSE findDupl;
  END;
/

BEGIN
  FIX_DUPLICATE_PLAYER_STATS();
END;
/

--1_5--
DROP FUNCTION calc_tendex;



CREATE OR REPLACE FUNCTION calc_tendex(id IN VARCHAR2, nbaYear IN NUMBER, team IN VARCHAR2)
  RETURN NUMBER AS
  tendex NUMBER(6, 4);
  temp   NUMBER;
  BEGIN

    SELECT MINUTES
    INTO temp
    FROM PLAYERS_TEAMS pl
    WHERE pl.PLAYERID = id AND pl.YEAR = nbaYear AND pl.TEAMID = team;

    IF temp = 0
    THEN
      tendex := 0;
      RETURN tendex;
    ELSE
      SELECT (POINTS + REBOUNDS + ASSISTS + STEALS + BLOCKS - TURNOVERS - FOULS - (FGATTEMPTED - FGMADE)
              - (FTATTEMPTED - FTMADE) / 2) / MINUTES
      INTO tendex
      FROM PLAYERS_TEAMS pl
      WHERE pl.PLAYERID = id AND pl.YEAR = nbaYear AND pl.TEAMID = team;
      RETURN tendex;
    END IF;
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
  result NUMBER(6, 4);
BEGIN
  id := 'brezepr01';
  year := 2009;
  team := 'CHA';
  result := calc_tendex(id, year, team);
  dbms_output.put_line(' Player ' || id || ' in NBA Team ' || team || ' for the year ' || year || ' has ' || result);
END;
/

--helper--
DROP PROCEDURE insertScore;
CREATE OR REPLACE PROCEDURE insertScore AS
  nbaYear PLAYERS_TEAMS.YEAR%TYPE;
  plId    PLAYERS_TEAMS.PLAYERID%TYPE;
  teId    PLAYERS_TEAMS.TEAMID%TYPE;
  scorePl PLAYERS_TEAMS.SCORE%TYPE;

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
  insertScore();
END;
/

--2_1--
DROP TABLE TEMP_CLOB_TAB;
DROP PROCEDURE get_top_players_xml;
CREATE TABLE TEMP_CLOB_TAB (
  id  NUMBER,
  xml XMLTYPE
);

CREATE OR REPLACE PROCEDURE get_top_players_xml(nbaYear IN NUMBER, n IN NUMBER) AS
  l_domdoc            dbms_xmldom.DOMDocument;
  l_xmltype           XMLTYPE;

  l_root_node         dbms_xmldom.DOMNode;

  l_nba_element       dbms_xmldom.DOMElement;
  l_nba_node          dbms_xmldom.DOMNode;

  l_div_element       dbms_xmldom.DOMElement;
  l_div_node          dbms_xmldom.DOMNode;

  l_player_element    dbms_xmldom.DOMElement;
  l_player_node       dbms_xmldom.DOMNode;

  l_id_node           dbms_xmldom.DOMNode;
  l_id_textnode       dbms_xmldom.DOMNode;

  l_name_node         dbms_xmldom.DOMNode;
  l_name_textnode     dbms_xmldom.DOMNode;

  l_position_node     dbms_xmldom.DOMNode;
  l_position_textnode dbms_xmldom.DOMNode;

  l_points_node       dbms_xmldom.DOMNode;
  l_points_textnode   dbms_xmldom.DOMNode;

  l_minutes_node      dbms_xmldom.DOMNode;
  l_minutes_textnode  dbms_xmldom.DOMNode;

  l_index_node        dbms_xmldom.DOMNode;
  l_index_textnode    dbms_xmldom.DOMNode;

  l_division_node     dbms_xmldom.DOMNode;
  l_division_textnode dbms_xmldom.DOMNode;

  l_team_node         dbms_xmldom.DOMNode;

  l_teamID_node       dbms_xmldom.DOMNode;
  l_teamID_textnode   dbms_xmldom.DOMNode;

  l_teamName_node     dbms_xmldom.DOMNode;
  l_teamName_textnode dbms_xmldom.DOMNode;

  BEGIN
    -- Create an empty XML document
    l_domdoc := dbms_xmldom.newDomDocument;
    -- Create a root node
    l_root_node := dbms_xmldom.makeNode(l_domdoc);

    -- Create a new node nba and add it to the root node
    l_nba_element := dbms_xmldom.createElement(l_domdoc, 'nba');
    l_nba_node := dbms_xmldom.appendChild(l_root_node
    , dbms_xmldom.makeNode(l_nba_element)
    );
    dbms_xmldom.setAttribute(l_nba_element, 'dataset', 'topplayers');

    FOR r_div IN (SELECT te.DIVISION
                  FROM TEAMS te
                  WHERE te.YEAR = nbaYear AND te.DIVISION IN ('East', 'West')
                  GROUP BY te.DIVISION)
    LOOP

      -- For each record, create a new division element with the DIVISION as attribute.
      -- and add this new division element to the nba node
      l_div_element := dbms_xmldom.createElement(l_domdoc, 'division');
      dbms_xmldom.setAttribute(l_div_element, 'id', r_div.DIVISION);
      l_div_node := dbms_xmldom.appendChild(l_nba_node
      , dbms_xmldom.makeNode(l_div_element)
      );

      FOR r_plr IN (SELECT *
                    FROM (SELECT
                            pl.PLAYERID,
                            pl.FIRSTNAME,
                            pl.LASTNAME,
                            pl.POSITION,
                            pl_te.POINTS,
                            pl_te.MINUTES,
                            pl_te.SCORE,
                            t.DIVISION,
                            t.TEAMID,
                            t.TEAMNAME
                          FROM PLAYERS pl
                            JOIN PLAYERS_TEAMS
                                 pl_te ON pl.PLAYERID = pl_te.PLAYERID
                            JOIN TEAMS t ON pl_te.TEAMID = t.TEAMID AND pl_te.YEAR = t.YEAR
                          WHERE t.YEAR = nbaYear AND t.DIVISION = r_div.DIVISION
                          ORDER BY SCORE DESC

                    )
                    WHERE ROWNUM <= n)
      LOOP
        -- For each record, create a new player element.
        -- and add this new player element to the division node
        l_player_element := dbms_xmldom.createElement(l_domdoc, 'player');
        l_player_node := dbms_xmldom.appendChild(l_div_node
        , dbms_xmldom.makeNode(l_player_element)
        );

        -- Each player node will get a id node which contains the PLAYERID as text
        l_id_node := dbms_xmldom.appendChild(l_player_node
        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'id'))
        );
        l_id_textnode := dbms_xmldom.appendChild(l_id_node
        , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, r_plr.PLAYERID))
        );

        -- Each player node will get a name node which contains the FIRSTNAME AND LASTNAME as text
        l_name_node := dbms_xmldom.appendChild(l_player_node
        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'name'))
        );
        l_name_textnode := dbms_xmldom.appendChild(l_name_node
        , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, r_plr.FIRSTNAME || ' ' || r_plr.LASTNAME))
        );

        -- Each player node will get a position node which contains the POSITION as text
        l_position_node := dbms_xmldom.appendChild(l_player_node
        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'position'))
        );
        l_position_textnode := dbms_xmldom.appendChild(l_position_node
        , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, r_plr.POSITION))
        );

        -- Each player node will get a points node which contains the POINTS as text
        l_points_node := dbms_xmldom.appendChild(l_player_node
        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'points'))
        );
        l_points_textnode := dbms_xmldom.appendChild(l_points_node
        , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, r_plr.POINTS))
        );

        -- Each player node will get a minutes node which contains the MINUTES as text
        l_minutes_node := dbms_xmldom.appendChild(l_player_node
        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'minutes'))
        );
        l_minutes_textnode := dbms_xmldom.appendChild(l_minutes_node
        , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, r_plr.MINUTES))
        );

        -- Each player node will get a index node which contains the SCORE as text
        l_index_node := dbms_xmldom.appendChild(l_player_node
        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'index'))
        );
        l_index_textnode := dbms_xmldom.appendChild(l_index_node
        , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, r_plr.SCORE))
        );

        -- Each player node will get a division node which contains the DIVISION as text
        l_division_node := dbms_xmldom.appendChild(l_player_node
        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'plDivision'))
        );
        l_division_textnode := dbms_xmldom.appendChild(l_division_node
        , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, r_plr.DIVISION))
        );

        -- Each player node will get a team node which contains the teamId and teamName
        l_team_node := dbms_xmldom.appendChild(l_player_node
        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'team'))
        );

        -- Each player node will get a teamId node which contains the TEAMID as text
        l_teamID_node := dbms_xmldom.appendChild(l_team_node
        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'teamId'))
        );
        l_teamID_node := dbms_xmldom.appendChild(l_teamID_node
        , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, r_plr.TEAMID))
        );

        -- Each player node will get a teamName node which contains the TEAMNAME as text
        l_teamName_node := dbms_xmldom.appendChild(l_team_node
        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'teamName'))
        );
        l_teamName_textnode := dbms_xmldom.appendChild(l_teamName_node
        , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, r_plr.TEAMNAME))
        );
      END LOOP;
    END LOOP;

    l_xmltype := dbms_xmldom.getXmlType(l_domdoc);
    dbms_xmldom.freeDocument(l_domdoc);

    DELETE FROM TEMP_CLOB_TAB
    WHERE ID = 1;
    INSERT INTO TEMP_CLOB_TAB VALUES (1, l_xmltype);


  END;
/

 DECLARE
  num  NUMBER(6);
  year NUMBER(6);

BEGIN
  year := 2009;
  num := 12;
  get_top_players_xml(year, num);
END;
/

SELECT *
FROM TEMP_CLOB_TAB;

--2_2--
DROP PROCEDURE get_allstar_players_xml;
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
                       FROM PLAYERS pl
                         JOIN PLAYERS_TEAMS plt ON pl.PLAYERID = plt.PLAYERID
                         JOIN ALLSTARS allstr ON plt.PLAYERID = allstr.PLAYERID AND plt.YEAR = allstr.YEAR
                         JOIN TEAMS t ON plt.TEAMID = t.TEAMID AND plt.YEAR = t.YEAR
                       WHERE allstr.YEAR = 2009 AND allstr.CONFERENCE IN ('East', 'West')
                       GROUP BY allstr.CONFERENCE)
    )
    INTO result
    FROM dual;

    DELETE FROM TEMP_CLOB_TAB
    WHERE ID = 2;
    INSERT INTO TEMP_CLOB_TAB VALUES (2, result);
  END;
/

BEGIN
  get_allstar_players_xml();
END;
/

SELECT *
FROM TEMP_CLOB_TAB;
