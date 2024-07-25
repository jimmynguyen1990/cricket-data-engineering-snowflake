USE ROLE accountadmin;
USE WAREHOUSE compute_wh;
USE SCHEMA cricket.clean;

/*MATCHES*/
--step 1
--the meta column has no real domain value, and it just captures the json file version, therefore it is an object data type.
--extract elements from object data type
SELECT
    meta['data_version']::text AS data_version,
    meta['created']::date AS date_created,
    meta['revision']::number AS revision
FROM cricket.raw.match_raw_tbl;

--step 2
--use json crack (paid version for large data) to analyse the structure of important information to extract useful data
SELECT
    info:match_type_number::int AS match_type_number,
    info:match_type::text AS match_type,
    info:season::text AS season,
    info:overs::int AS overs,
    info:city::text AS city,
    info:venue::text AS venue
FROM cricket.raw.match_raw_tbl;

--after analyse the above general table for info, write sql script to generate a table containing more detailed data for all matches
CREATE OR REPLACE TRANSIENT TABLE cricket.clean.match_detail_clean_tbl AS
    SELECT
        info:match_type_number::int AS match_type_number,
        info:event.name::text AS event_name,
        CASE WHEN info:event.match_number is not null THEN info:event.match_number::text
             WHEN info:event.stage is not null THEN info:event.stage::text
             ELSE 'NA'
        END AS match_stage,
        info:dates[0]::date AS event_date,
        date_part('year', info:dates[0]::date) AS event_year,
        date_part('month', info:dates[0]::date) AS event_month,
        date_part('day', info:dates[0]::date) AS event_day,
        info:match_type::text AS match_type,
        info:season::text AS season,
        info:team_type::text AS team_type,
        info:overs::text AS overs,
        info:city::text AS city,
        info:venue::text AS venue,
        info:gender::text AS gender,
        info:teams[0]::text AS first_team,
        info:teams[1]::text AS second_team,
        CASE WHEN info:outcome.winner is not null THEN 'Result declared'
             WHEN info:outcome.result = 'tie' THEN 'Tie'
             WHEN info:outcome.result = 'no result'THEN 'No result'
             ELSE info:outcome.result::text
        END AS match_result,
        CASE WHEN info:outcome.winner is not null THEN info:outcome.winner::text
             ELSE 'NA'
        END AS winner,
        info:toss.winner::text AS toss_winner,
        initcap(info:toss.decision::text) AS toss_decision,
        stg_file_name,
        stg_file_row_number,
        stg_file_hashkey,
        stg_modified_ts
    FROM cricket.raw.match_raw_tbl;

/*CHECKING DUPLICATES*/
--check if there is any duplicate of match_type_number(this will be primary key) in cricket.clean.match_detail_clean_tbl
--we find out that there are two items having duplicate match_type_number (4714 and 3780)
SELECT m.match_type_number, m.event_name, m.stg_file_name
FROM cricket.clean.match_detail_clean_tbl m
WHERE m.match_type_number IN (SELECT m1.match_type_number
                              FROM cricket.clean.match_detail_clean_tbl m1
                              GROUP BY m1.match_type_number
                              HAVING COUNT(*) > 1)
ORDER BY m.match_type_number;


--deleting match_type_number 3780 with event_name is NA in cricket.clean.match_detail_clean_tbl and cricket.raw.match_raw_tbl
DELETE FROM cricket.raw.match_raw_tbl r
WHERE r.stg_file_name = (SELECT m.stg_file_name
                         FROM cricket.clean.match_detail_clean_tbl m
                         WHERE m.match_type_number = 3780 AND m.event_name is null);

DELETE FROM cricket.clean.match_detail_clean_tbl m
WHERE m.match_type_number = 3780 AND m.event_name is null;

--updating match_type_number 4714 in cricket.clean.match_detail_clean_tbl and cricket.raw.match_raw_tbl with latest event_date to 4715 since there is not yet 4715 in the table

UPDATE cricket.raw.match_raw_tbl r
    SET r.info = parse_json('{"balls_per_over":6,"city":"Gqeberha","dates":["2023-12-19"],"event":{"match_number":2,"name":"India tour of South Africa"},"gender":"male","match_type":"ODI","match_type_number":4715,"officials":{"match_referees":["BC Broad"],"reserve_umpires":["A Paleker"],"tv_umpires":["RA Kettleborough"],"umpires":["Ahsan Raza","BP Jele"]},"outcome":{"by":{"wickets":8},"winner":"South Africa"},"overs":50,"player_of_match":["T de Zorzi"],"players":{"India":["RD Gaikwad","B Sai Sudharsan","Tilak Varma","KL Rahul","SV Samson","RK Singh","AR Patel","Kuldeep Yadav","Arshdeep Singh","Avesh Khan","Mukesh Kumar"],"South Africa":["RR Hendricks","T de Zorzi","HE van der Dussen","AK Markram","H Klaasen","DA Miller","PWA Mulder","KA Maharaj","N Burger","LB Williams","BE Hendricks"]},"registry":{"people":{"A Paleker":"634b11ac","AK Markram":"6a26221c","AR Patel":"2e171977","Ahsan Raza":"e0e5b209","Arshdeep Singh":"244048f6","Avesh Khan":"eef2536f","B Sai Sudharsan":"d5130a30","BC Broad":"d6a7dd38","BE Hendricks":"b56dc5f7","BP Jele":"7bb1331e","DA Miller":"d67d5f00","H Klaasen":"235c2bb6","HE van der Dussen":"9948e262","K Verreynne":"bf814547","KA Maharaj":"0b60eb09","KL Rahul":"b17e2f24","Kuldeep Yadav":"8d2c70ad","LB Williams":"a1d95bd8","Mukesh Kumar":"2cffab74","N Burger":"465aa633","PWA Mulder":"c96f6ac5","RA Kettleborough":"4017868f","RD Gaikwad":"45a43fe2","RK Singh":"0a509d6b","RR Hendricks":"b8cc58c9","SV Samson":"a4cc73aa","T de Zorzi":"d3a1c63d","Tilak Varma":"b0482a1d"}},"season":"2023/24","team_type":"international","teams":["India","South Africa"],"toss":{"decision":"field","winner":"South Africa"},"venue":"St George\'s Park, Gqeberha"}')
    WHERE r.stg_file_name = (SELECT m1.stg_file_name
                             FROM cricket.clean.match_detail_clean_tbl m1
                             WHERE m1.match_type_number = 4714 AND m1.event_date = (SELECT max(m2.event_date)
                                                                                      FROM cricket.clean.match_detail_clean_tbl m2
                                                                                      WHERE m2.match_type_number = 4714));

UPDATE cricket.clean.match_detail_clean_tbl m
    SET m.match_type_number = 4715
    WHERE m.event_date = (SELECT max(m1.event_date)
                          FROM cricket.clean.match_detail_clean_tbl m1
                          WHERE m1.match_type_number = 4714)

--check again cricket.raw.match_raw_tbl and cricket.clean.match_detail_clean_tbl 
--every match_type_number now is distinct to be Primary Key (1467 items)
select m.match_type_number, count(*) as num
from cricket.clean.match_detail_clean_tbl m
group by m.match_type_number

--set Primary key for match_detail_clean_tbl
ALTER TABLE cricket.clean.match_detail_clean_tbl
ADD CONSTRAINT pk_match_id
PRIMARY KEY (match_type_number);
