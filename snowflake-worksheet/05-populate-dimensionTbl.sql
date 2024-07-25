USE ROLE accountadmin;
USE WAREHOUSE compute_wh;
USE SCHEMA cricket.consumption;


/*ADD DATA FROM CLEAN SCHEMA TO DIMENSION TABLES*/

/*team_tbl*/
INSERT INTO cricket.consumption.team_tbl(team_name)
SELECT DISTINCT team_name FROM(
    SELECT first_team AS team_name FROM cricket.clean.match_detail_clean_tbl
    UNION ALL
    SELECT second_team FROM cricket.clean.match_detail_clean_tbl
    UNION ALL
    SELECT winner FROM cricket.clean.match_detail_clean_tbl
);

/*player_tbl*/
INSERT INTO cricket.consumption.player_tbl(team_id, player_name)
SELECT t.team_id, p.player_name
FROM cricket.clean.player_clean_tbl p
    LEFT JOIN cricket.consumption.team_tbl t
    ON p.country = t.team_name
GROUP BY t.team_id, p.player_name;

/*date_tbl*/
--dayofweek: 0-6 with Sunday is 0
INSERT INTO cricket.consumption.date_tbl 
    (full_date, day_num, month_num, year_num, quarter_num, day_of_week,
     day_of_month, day_of_year, day_of_week_name, is_weekend)
SELECT m.event_date, date_part('day', m.event_date), date_part('month', m.event_date),
       date_part('year', m.event_date), quarter(m.event_date), dayofweek(m.event_date),
       dayofmonth(m.event_date), dayofyear(m.event_date), to_varchar(m.event_date, 'DY'),
       iff(dayofweek(m.event_date) IN (0,6), True, False)
FROM (SELECT DISTINCT event_date
      FROM cricket.clean.match_detail_clean_tbl
      ORDER BY event_date) m
;


/*match_type_tbl*/
INSERT INTO cricket.consumption.match_type_tbl (match_type)
SELECT m.match_type
FROM cricket.clean.match_detail_clean_tbl m
GROUP BY m.match_type;

/*venue_tbl*/
--split the venue to get the first component which is the real venue name excluding the city
--fill in the missing city for venue that has previous eligble city name 
INSERT INTO cricket.consumption.venue_tbl(venue_name, city)
SELECT m.venue,
       CASE WHEN m.city is null THEN 'NA'
       ELSE m.city
       END AS city
FROM (SELECT split_part(venue, ',', 0) AS venue,
             last_value(city ignore nulls) over (partition by venue order by venue, city) AS city
      FROM cricket.clean.match_detail_clean_tbl
      ORDER BY venue, city) m
GROUP BY venue, m.city


/*referee_tbl*/
--extract from raw schema
SELECT
    info:officials.match_referees[0]::text AS match_referee,
    info:officials.reserve_umpires[0]::text AS reserve_umpire,
    info:officials.tv_umpires[0]::text AS tv_umpire,
    info:officials.umpires[0]::text AS first_umpire,
    info:officials.umpires[1]::text AS second_umpire
FROM cricket.raw.match_raw_tbl;

/*match_fact_tbl*/
INSERT INTO cricket.consumption.match_fact_tbl
    (match_id, date_id, first_team_id, second_team_id, match_type_id,
     venue_id, city, total_overs, balls_per_over, toss_winner_team_id,toss_decision,
     match_result, winner_team_id, overs_played_by_first_team, bowls_played_by_first_team,
     extra_runs_scored_by_first_team, total_score_by_first_team, wicket_lost_by_first_team,
     overs_played_by_second_team, bowls_played_by_second_team, extra_runs_scored_by_second_team,
     total_score_by_second_team, wicket_lost_by_second_team)

SELECT m.match_type_number, d.date_id, ft.team_id AS first_team_id, st.team_id AS second_team_id,
       mt.match_type_id, v.venue_id, v.city, m.overs, 6 AS balls_per_over,
       tos.team_id AS toss_winner_team_id, m.toss_decision, m.match_result, w.team_id AS winner_team_id,

       zeroifnull(t1.over_played) AS overs_played_by_first_team, zeroifnull(t1.total_bowls) AS bowls_played_by_first_team,
       zeroifnull(t1.extra_runs) AS extra_runs_scored_by_first_team, zeroifnull(t1.total) AS total_score_by_first_team,
       zeroifnull(t1.wickets_loss) AS wicket_lost_by_first_team,

       zeroifnull(t2.over_played) AS overs_played_by_first_team, zeroifnull(t2.total_bowls) AS bowls_played_by_first_team,
       zeroifnull(t2.extra_runs) AS extra_runs_scored_by_first_team, zeroifnull(t2.total) AS total_score_by_first_team,
       zeroifnull(t2.wickets_loss) AS wicket_lost_by_first_team,
       
FROM cricket.clean.match_detail_clean_tbl m
    LEFT JOIN cricket.consumption.date_tbl d ON m.event_date = d.full_date
    LEFT JOIN cricket.consumption.team_tbl ft ON m.first_team = ft.team_name
    LEFT JOIN cricket.consumption.team_tbl st ON m.second_team = st.team_name
    LEFT JOIN cricket.consumption.match_type_tbl mt ON m.match_type = mt.match_type
    LEFT JOIN cricket.consumption.venue_tbl v ON (split_part(m.venue, ',', 0) = v.venue_name AND m.city = v.city)
    LEFT JOIN cricket.consumption.team_tbl tos ON m.toss_winner = tos.team_name
    LEFT JOIN cricket.consumption.team_tbl w ON m.winner = w.team_name
    LEFT JOIN (SELECT dl1.match_type_number AS match_number, dl1.team_name AS team_name, max(over) AS over_played,
                      sum(runs) AS runs, sum(extras) AS extras, sum(extra_runs) AS extra_runs, sum(total) AS total,
                      count(over) AS total_bowls, dl2.wickets AS wickets_loss
               FROM cricket.clean.delivery_clean_tbl dl1
                    LEFT JOIN (SELECT d.match_type_number AS match_id, d.team_name AS team, count(*) AS wickets
                               FROM cricket.clean.delivery_clean_tbl d
                               WHERE player_out_kind is not null
                               GROUP BY ALL) dl2    
                    ON dl1.match_type_number = dl2.match_id AND dl1.team_name = dl2.team
                    GROUP BY ALL) t1
        ON (m.match_type_number = t1.match_number AND m.first_team = t1.team_name)
        
    LEFT JOIN (SELECT dl1.match_type_number AS match_number, dl1.team_name AS team_name, max(over) AS over_played,
                      sum(runs) AS runs, sum(extras) AS extras, sum(extra_runs) AS extra_runs, sum(total) AS total,
                      count(over) AS total_bowls, dl2.wickets AS wickets_loss
               FROM cricket.clean.delivery_clean_tbl dl1
                    LEFT JOIN (SELECT d.match_type_number AS match_id, d.team_name AS team, count(*) AS wickets
                               FROM cricket.clean.delivery_clean_tbl d
                               WHERE player_out_kind is not null
                               GROUP BY ALL) dl2    
                    ON dl1.match_type_number = dl2.match_id AND dl1.team_name = dl2.team
                    GROUP BY ALL) t2
        ON (m.match_type_number = t2.match_number AND m.second_team = t2.team_name)
ORDER BY match_type_number;    

