CREATE OR REPLACE PROCEDURE xml(nbaYear IN NUMBER) AS
  l_domdoc            dbms_xmldom.DOMDocument;
  l_xmltype           XMLTYPE;

  l_root_node         dbms_xmldom.DOMNode;
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
    l_nba_node := dbms_xmldom.appendChild(l_root_node
    , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'nba'))
    );
    dbms_xmldom.setAttribute(l_nba_node, 'dataset', 'topplayers');

    FOR div IN (SELECT
                  pl.PLAYERID,
                  pl.FIRSTNAME || ' ' || pl.LASTNAME,
                  pl.POSITION,
                  pl_te.POINTS,
                  pl_te.MINUTES,
                  pl_te.SCORE,
                  t.DIVISION,
                  t.TEAMID,
                  t.TEAMNAME
                FROM PLAYERS pl
                  JOIN PLAYERS_TEAMS pl_te ON pl.PLAYERID = pl_te.PLAYERID
                  JOIN TEAMS t ON pl_te.TEAMID = t.TEAMID AND pl_te.YEAR = t.YEAR
                WHERE t.YEAR = nbaYear AND t.DIVISION IN ('East', 'West'))
    LOOP

END LOOP;
    END;
