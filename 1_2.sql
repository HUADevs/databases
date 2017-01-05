CREATE PROCEDURE fix_player_metrics AS
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
      UPDATE PLAYERS SET HEIGHT = cm_height , WEIGHT = kg_weight WHERE CURRENT OF mCursor;
    END LOOP;
    CLOSE mCursor;
  END;
/

BEGIN
  FIX_PLAYER_METRICS();
END;
/