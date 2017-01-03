DROP TABLE ALLSTARS;
DROP TABLE PLAYERS_TEAMS;
DROP TABLE TEAMS;
DROP TABLE PLAYERS;
DROP TABLE duplicate_player_stats;
DROP PROCEDURE FIX_PLAYER_METRICS;
DROP PROCEDURE FIX_DUPLICATE_PLAYER_STATS;


CREATE TABLE ALLSTARS AS SELECT * FROM XSALES.ALLSTARS;


CREATE TABLE PLAYERS AS SELECT * FROM XSALES.PLAYERS;


CREATE TABLE PLAYERS_TEAMS AS SELECT * FROM XSALES.PLAYERS_TEAMS;


CREATE TABLE TEAMS AS SELECT * FROM XSALES.TEAMS;


ALTER TABLE PLAYERS
ADD PRIMARY KEY(PLAYERID);

ALTER TABLE ALLSTARS
ADD PRIMARY KEY(YEAR, PLAYERID);

ALTER TABLE TEAMS
ADD PRIMARY KEY(TEAMID, YEAR);

ALTER TABLE ALLSTARS
ADD CONSTRAINT allstarsforeign FOREIGN KEY (PLAYERID) REFERENCES PLAYERS (PLAYERID) ON DELETE CASCADE;

ALTER TABLE PLAYERS_TEAMS
ADD CONSTRAINT play_team_1 FOREIGN KEY (PLAYERID) REFERENCES PLAYERS (PLAYERID) ON DELETE CASCADE;

ALTER TABLE PLAYERS_TEAMS
ADD CONSTRAINT play_team_2 FOREIGN KEY (TEAMID, YEAR) REFERENCES TEAMS (TEAMID, YEAR) ON DELETE CASCADE;

