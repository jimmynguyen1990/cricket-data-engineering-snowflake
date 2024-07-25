USE ROLE accountadmin;
USE WAREHOUSE compute_wh;
USE SCHEMA cricket.clean;

/*PLAYERS*/
--extract players
--step 1
SELECT
    info:match_type_number::int AS match_type_number,
    info:players,
    info:teams
FROM cricket.raw.match_raw_tbl;
    
--step 2
SELECT
    info:match_type_number::int AS match_type_number,
    info:players,
    info:teams
FROM cricket.raw.match_raw_tbl
WHERE match_type_number = 3839;

--step 3
SELECT
    info:match_type_number::int AS match_type_number,
    --p.*
    p.key::text AS country
FROM cricket.raw.match_raw_tbl,
LATERAL FLATTEN (input => info:players) p
WHERE match_type_number = 3839;

--step 4
SELECT
    info:match_type_number::int AS match_type_number,
    --p.*
    --t.*,
    t.value::text AS player_name,
    p.key::text AS country
FROM cricket.raw.match_raw_tbl,
LATERAL FLATTEN (input => info:players) p,
LATERAL FLATTEN (input => p.value) t
WHERE match_type_number = 3839;

--create table for players
CREATE OR REPLACE TRANSIENT TABLE cricket.clean.player_clean_tbl AS
    SELECT
        info:match_type_number::int AS match_type_number,
        t.value::text AS player_name,
        p.key::text AS country,
        stg_file_name,
        stg_file_row_number,
        stg_file_hashkey,
        stg_modified_ts
    FROM cricket.raw.match_raw_tbl,
    LATERAL FLATTEN (input => info:players) p,
    LATERAL FLATTEN (input => p.value) t;

--check deplicates => 2467 items (good)
select count(distinct match_type_number)
from cricket.clean.player_clean_tbl

--add NOT NULL contraint
ALTER TABLE cricket.clean.player_clean_tbl
MODIFY COLUMN match_type_number SET not null;

ALTER TABLE cricket.clean.player_clean_tbl
MODIFY COLUMN country SET not null;

ALTER TABLE cricket.clean.player_clean_tbl
MODIFY COLUMN player_name SET not null;

--set Foreign key relationship for player_clean_tbl
ALTER TABLE cricket.clean.player_clean_tbl
ADD CONSTRAINT fk_match_id
FOREIGN KEY (match_type_number)
REFERENCES cricket.clean.match_detail_clean_tbl (match_type_number);
