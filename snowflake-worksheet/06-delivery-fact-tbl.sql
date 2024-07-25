USE ROLE accountadmin;
USE WAREHOUSE compute_wh;
USE SCHEMA cricket.consumption;

/*Create table delivery_fact_tbl*/
CREATE OR REPLACE TABLE delivery_fact(
    match_id int PRIMARY KEY,
    team_id int,
    bowler_id int,
    batter_id int,
    non_striker_id int,
    over int,
    runs int,
    extra_runs int,
    extra_type varchar(300),
    player_out varchar(300),
    player_out_kind varchar(300),

    CONSTRAINT fk_del_match_id FOREIGN KEY(match_id) REFERENCES cricket.consumption.match_fact_tbl(match_id),
    CONSTRAINT fk_del_team_id FOREIGN KEY(team_id) REFERENCES cricket.consumption.team_tbl(team_id),
    CONSTRAINT fk_bowler FOREIGN KEY(bowler_id) REFERENCES cricket.consumption.player_tbl(player_id),
    CONSTRAINT fk_batter FOREIGN KEY(batter_id) REFERENCES cricket.consumption.player_tbl(player_id),
    CONSTRAINT fk_nonstriker FOREIGN KEY(non_striker_id) REFERENCES cricket.consumption.player_tbl(player_id)
);

/*Populate data into delivery_fact_tbl*/
INSERT INTO cricket.consumption.delivery_fact
SELECT
    d.match_type_number as match_id,
    t.team_id,
    p1.player_id AS bowler_id,
    p2.player_id AS batter_id,
    p3.player_id AS non_striker_id,
    d.over, d.runs,
    CASE WHEN d.extra_runs is null THEN 0 ELSE d.extra_runs END AS extra_runs,
    CASE WHEN d.extra_type is null THEN 'None' ELSE d.extra_type END AS extra_type,
    CASE WHEN d.player_out is null THEN 'None' ELSE d.player_out END AS player_out,
    CASE WHEN d.player_out_kind is null THEN 'None' ELSE d.player_out_kind END AS player_out_kind
FROM cricket.clean.delivery_clean_tbl d

    JOIN cricket.consumption.team_tbl t  ON d.team_name = t.team_name
    JOIN cricket.consumption.player_tbl p1  ON d.bowler = p1.player_name
    JOIN cricket.consumption.player_tbl p2  ON d.batter = p2.player_name
    JOIN cricket.consumption.player_tbl p3  ON d.non_striker = p3.player_name


    