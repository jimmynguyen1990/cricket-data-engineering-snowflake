USE ROLE accountadmin;
USE WAREHOUSE compute_wh;
USE SCHEMA cricket.raw;

--create a table inside the raw schema
CREATE OR REPLACE TRANSIENT TABLE cricket.raw.match_raw_tbl
(
    meta object not null,
    info variant not null,
    innings array not null,
    stg_file_name text not null,
    stg_file_row_number int not null,
    stg_file_hashkey text not null,
    stg_modified_ts timestamp not null
)
COMMENT = "This is a table in raw schema to store all the json data file with root elements extracted.";

--load data from 2,468 json files from land schema to match_raw_tbl.
COPY INTO cricket.raw.match_raw_tbl FROM
(
    SELECT
        t.$1:meta::object as meta,
        t.$1:info::variant as info,
        t.$1:innings::array as innings,
        metadata$filename,
        metadata$file_row_number,
        metadata$file_content_key,
        metadata$file_last_modified
    FROM @cricket.land.my_stage/cricket/json (file_format => 'cricket.land.cricket_json_format') t
)
ON_ERROR = CONTINUE;

--count how many items there are in match_raw_tbl.
--there are 2,467 items while there are 2,468 json files => 1 file is currently missing.
--go to match_raw_tbl in cricket.raw to check the "copy history" in order to see the failed loading file which is 64933.json (failure at line 4063, position 27).
--use vscode to open and fix the failure of 64933.json then load it again.
SELECT COUNT(*) FROM cricket.raw.match_raw_tbl;
