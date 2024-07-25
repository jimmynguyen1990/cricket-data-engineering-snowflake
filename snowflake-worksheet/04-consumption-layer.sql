USE ROLE accountadmin;
USE WAREHOUSE compute_wh;
USE SCHEMA cricket.consumption;

/*CREATE TABLES (DIMENSIONS) for data*/

/*Table (dimension) for match date*/
CREATE OR REPLACE TABLE cricket.consumption.date_tbl(
    date_id int PRIMARY KEY autoincrement,
    full_date date,
    day_num int,
    month_num int,
    year_num int,
    quarter_num int,
    day_of_week int,
    day_of_month int,
    day_of_year int,
    day_of_week_name varchar(3),
    is_weekend boolean
);

/*Table for referees, umpires*/
CREATE OR REPLACE TABLE cricket.consumption.referee_tbl(
    referee_id int PRIMARY KEY autoincrement,
    referee_name text not null,
    referee_type text not null
);

/*Table for teams*/
CREATE OR REPLACE TABLE cricket.consumption.team_tbl(
    team_id int PRIMARY KEY autoincrement,
    team_name text not null
);

/*Table for player*/
CREATE OR REPLACE TABLE cricket.consumption.player_tbl(
    player_id int PRIMARY KEY autoincrement,
    team_id int not null,
    player_name text not null,

    CONSTRAINT fk_player_team FOREIGN KEY (team_id) REFERENCES cricket.consumption.team_tbl(team_id) 
);

/*Table for venues*/
CREATE OR REPLACE TABLE cricket.consumption.venue_tbl(
    venue_id int PRIMARY KEY autoincrement,
    venue_name text not null,
    city text not null,
    state text,
    country text,
    continent text,
    end_names text,
    capacity number,
    pitch text,
    flood_light boolean,
    established_date date,
    playing_area text,
    other_sports text,
    curator text,
    lattitude number(10,6),
    longitude number(10,6)
);

/*Table for match types*/
CREATE OR REPLACE TABLE cricket.consumption.match_type_tbl(
    match_type_id int PRIMARY KEY autoincrement,
    match_type text not null
);

/*Table for match facts*/
CREATE OR REPLACE TABLE cricket.consumption.match_fact_tbl(
    match_id int PRIMARY KEY autoincrement,
    date_id int not null,
    referee_id int,
    first_team_id int not null,
    second_team_id int not null,
    match_type_id int not null,
    venue_id int,
    city text,
    total_overs number(3),
    balls_per_over number(1),

    overs_played_by_first_team number(2),
    bowls_played_by_first_team number(3),
    extra_bowls_played_by_first_team number(3),
    extra_runs_scored_by_first_team number(3),
    fours_by_first_team number(3),
    sixes_by_first_team number(3),
    total_score_by_first_team number(3),
    wicket_lost_by_first_team number(2),

    overs_played_by_second_team number(2),
    bowls_played_by_second_team number(3),
    extra_bowls_played_by_second_team number(3),
    extra_runs_scored_by_second_team number(3),
    fours_by_second_team number(3),
    sixes_by_second_team number(3),
    total_score_by_second_team number(3),
    wicket_lost_by_second_team number(2),

    toss_winner_team_id int not null,
    toss_decision text not null,
    match_result text not null,
    winner_team_id int not null,

    CONSTRAINT fk_matchdate_date FOREIGN KEY (date_id) REFERENCES cricket.consumption.date_tbl(date_id),
    CONSTRAINT fk_matchreferee_referee FOREIGN KEY (referee_id) REFERENCES cricket.consumption.referee_tbl(referee_id), 
    CONSTRAINT fk_firstteam_team FOREIGN KEY (first_team_id) REFERENCES cricket.consumption.team_tbl(team_id),
    CONSTRAINT fk_secondteam_team FOREIGN KEY (second_team_id) REFERENCES cricket.consumption.team_tbl(team_id), 
    CONSTRAINT fk_tosswinner_team FOREIGN KEY (toss_winner_team_id) REFERENCES cricket.consumption.team_tbl(team_id),
    CONSTRAINT fk_gamewinner_team FOREIGN KEY (winner_team_id) REFERENCES cricket.consumption.team_tbl(team_id),
    CONSTRAINT fk_matchtype FOREIGN KEY (match_type_id) REFERENCES cricket.consumption.match_type_tbl(match_type_id), 
    CONSTRAINT fk_matchvenue_venue FOREIGN KEY (venue_id) REFERENCES cricket.consumption.venue_tbl(venue_id)
);

desc table cricket.consumption.match_fact_tbl





