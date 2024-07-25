USE ROLE accountadmin;
USE WAREHOUSE compute_wh;
USE SCHEMA cricket.clean;

/*INNINGS*/
--extract elements from innings array
--step 1: explore the innings
SELECT 
    info:match_type_number::int AS match_type_number,
    innings
FROM cricket.raw.match_raw_tbl m
WHERE match_type_number = 3839;

--step 2: flatten innings
SELECT 
    m.info:match_type_number::int AS match_type_number,
    i.value:team::text AS team_name,
    m.innings,
    i.*
FROM cricket.raw.match_raw_tbl m,
LATERAL FLATTEN (input => m.innings) i
WHERE match_type_number = 3839;

--step 3: flatten overs of each team in innings, flatten deliveries in each over of each team
SELECT 
    m.info:match_type_number::int AS match_type_number,
    i.value:team::text AS team_name,
    o.value:over::int + 1 AS over,
    d.value:bowler::text AS bowler,
    d.value:batter::text AS batter,
    d.value:non_striker::text AS non_striker,
    d.value:runs.batter::text AS runs,
    d.value:runs.extras::text AS extras,
    d.value:runs.total::text AS total
FROM cricket.raw.match_raw_tbl m,
LATERAL FLATTEN (input => m.innings) i,
LATERAL FLATTEN (input => i.value:overs) o,
LATERAL FLATTEN (input => o.value:deliveries) d
WHERE match_type_number = 3836;

--step 4: flatten extras in deliveries
SELECT 
    m.info:match_type_number::int AS match_type_number,
    i.value:team::text AS team_name,
    o.value:over::int + 1 AS over,
    d.value:bowler::text AS bowler,
    d.value:batter::text AS batter,
    d.value:non_striker::text AS non_striker,
    d.value:runs.batter::text AS runs,
    d.value:runs.extras::text AS extras,
    d.value:runs.total::text AS total,
    e.key::text AS extra_type,
    e.value::number AS extra_runs
FROM cricket.raw.match_raw_tbl m,
LATERAL FLATTEN (input => m.innings) i,
LATERAL FLATTEN (input => i.value:overs) o,
LATERAL FLATTEN (input => o.value:deliveries) d,
LATERAL FLATTEN (input => d.value:extras, OUTER => TRUE) e
WHERE match_type_number = 3836;


--step 5: flatten wickets in deliveries
SELECT 
    m.info:match_type_number::int AS match_type_number,
    i.value:team::text AS team_name,
    o.value:over::int + 1 AS over,
    d.value:bowler::text AS bowler,
    d.value:batter::text AS batter,
    d.value:non_striker::text AS non_striker,
    d.value:runs.batter::text AS runs,
    d.value:runs.extras::text AS extras,
    d.value:runs.total::text AS total,
    e.key::text AS extra_type,
    e.value::number AS extra_runs,
    w.value:kind::text AS player_out_kind,
    w.value:fielders::variant AS player_out_fielders,
    w.value:player_out::text AS player_out
FROM cricket.raw.match_raw_tbl m,
LATERAL FLATTEN (input => m.innings) i,
LATERAL FLATTEN (input => i.value:overs) o,
LATERAL FLATTEN (input => o.value:deliveries) d,
LATERAL FLATTEN (input => d.value:extras, OUTER => TRUE) e,
LATERAL FLATTEN (input => d.value:wickets, OUTER => TRUE) w
WHERE match_type_number = 3836;

--create table cricket.clean.delivery_clean_tbl
CREATE OR REPLACE TRANSIENT TABLE cricket.clean.delivery_clean_tbl AS 
    SELECT 
        m.info:match_type_number::int AS match_type_number,
        i.value:team::text AS team_name,
        o.value:over::int + 1 AS over,
        d.value:bowler::text AS bowler,
        d.value:batter::text AS batter,
        d.value:non_striker::text AS non_striker,
        d.value:runs.batter::text AS runs,
        d.value:runs.extras::text AS extras,
        d.value:runs.total::text AS total,
        e.key::text AS extra_type,
        e.value::number AS extra_runs,
        w.value:kind::text AS player_out_kind,
        w.value:fielders::variant AS player_out_fielders,
        w.value:player_out::text AS player_out
    FROM cricket.raw.match_raw_tbl m,
    LATERAL FLATTEN (input => m.innings) i,
    LATERAL FLATTEN (input => i.value:overs) o,
    LATERAL FLATTEN (input => o.value:deliveries) d,
    LATERAL FLATTEN (input => d.value:extras, OUTER => TRUE) e,
    LATERAL FLATTEN (input => d.value:wickets, OUTER => TRUE) w;

--check deplicates => 2467 items (good)
SELECT DISTINCT match_type_number
FROM cricket.clean.delivery_clean_tbl;

--add NOT NULL contraint
ALTER TABLE cricket.clean.delivery_clean_tbl
MODIFY COLUMN match_type_number SET not null;


ALTER TABLE cricket.clean.delivery_clean_tbl 
MODIFY COLUMN team_name SET not null;

ALTER TABLE cricket.clean.delivery_clean_tbl 
MODIFY COLUMN over SET not null;

ALTER TABLE cricket.clean.delivery_clean_tbl 
MODIFY COLUMN bowler SET not null;

ALTER TABLE cricket.clean.delivery_clean_tbl 
MODIFY COLUMN batter SET not null;

ALTER TABLE cricket.clean.delivery_clean_tbl 
MODIFY COLUMN non_striker SET not null;

--add FK relationships
ALTER TABLE cricket.clean.delivery_clean_tbl
ADD CONSTRAINT fk_delivery_match_id
FOREIGN KEY (match_type_number)
REFERENCES cricket.clean.match_detail_clean_tbl;

