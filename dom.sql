CREATE OR REPLACE PROCEDURE xml(nbaYear IN NUMBER, n IN NUMBER) AS
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
                  WHERE te.YEAR = nbaYear AND te.DIVISION IN ('East', 'West') GROUP BY te.DIVISION)
    LOOP

      -- For each record, create a new division element with the DIVISION as attribute.
      -- and add this new division element to the nba node
      l_div_element := dbms_xmldom.createElement(l_domdoc, 'division');
      dbms_xmldom.setAttribute(l_div_element, 'id', r_div.DIVISION);
      l_div_node := dbms_xmldom.appendChild(l_nba_node
      , dbms_xmldom.makeNode(l_div_element)
      );

      FOR r_plr IN (SELECT
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
                      JOIN (SELECT * FROM PLAYERS_TEAMS ORDER BY SCORE DESC) pl_te ON pl.PLAYERID = pl_te.PLAYERID
                      JOIN TEAMS t ON pl_te.TEAMID = t.TEAMID AND pl_te.YEAR = t.YEAR
                    WHERE t.YEAR = nbaYear AND t.DIVISION=r_div.DIVISION AND ROWNUM<=n
      )
      LOOP
        /*IF r_div.DIVISION = r_plr.DIVISION
        THEN*/
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

          -- Each player node will get a points node which contains the POINTS as text
          l_minutes_node := dbms_xmldom.appendChild(l_player_node
          , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'minutes'))
          );
          l_minutes_textnode := dbms_xmldom.appendChild(l_minutes_node
          , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, r_plr.MINUTES))
          );

          -- Each player node will get a points node which contains the POINTS as text
          l_index_node := dbms_xmldom.appendChild(l_player_node
          , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'index'))
          );
          l_index_textnode := dbms_xmldom.appendChild(l_index_node
          , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, r_plr.SCORE))
          );

          -- Each player node will get a points node which contains the POINTS as text
          l_division_node := dbms_xmldom.appendChild(l_player_node
          , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'division'))
          );
          l_division_textnode := dbms_xmldom.appendChild(l_division_node
          , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, r_plr.DIVISION))
          );

          -- Each player node will get a points node which contains the POINTS as text
          l_team_node := dbms_xmldom.appendChild(l_player_node
          , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'team'))
          );

          -- Each player node will get a points node which contains the POINTS as text
          l_teamID_node := dbms_xmldom.appendChild(l_team_node
          , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'teamId'))
          );
          l_teamID_node := dbms_xmldom.appendChild(l_teamID_node
          , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, r_plr.TEAMID))
          );

          -- Each player node will get a points node which contains the POINTS as text
          l_teamName_node := dbms_xmldom.appendChild(l_team_node
          , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'teamName'))
          );
          l_teamName_textnode := dbms_xmldom.appendChild(l_teamName_node
          , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, r_plr.TEAMNAME))
          );
        /*END IF;*/
      END LOOP;
    END LOOP;

    l_xmltype := dbms_xmldom.getXmlType(l_domdoc);
    dbms_xmldom.freeDocument(l_domdoc);

    INSERT INTO TEMP_CLOB_TAB VALUES (2, l_xmltype);
  END;
/

 DECLARE
  num  NUMBER(6);
  year NUMBER(6);

BEGIN
  year := 2009;
  num := 12;
  xml(year,num);
END;
/

SELECT *
FROM TEMP_CLOB_TAB;