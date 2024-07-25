--select role
USE ROLE accountadmin;

--select compute warehouse
USE WAREHOUSE compute_wh;

--create a database named "cricket" with 4 schemas
CREATE DATABASE IF NOT EXISTS cricket;
CREATE OR REPLACE SCHEMA cricket.land;
CREATE OR REPLACE SCHEMA cricket.raw;
CREATE OR REPLACE SCHEMA cricket.clean;
CREATE OR REPLACE SCHEMA cricket.consumption;

SHOW SCHEMAS IN DATABASE cricket;

--switch to "land" schema;
USE SCHEMA cricket.land;

--create json file format
CREATE OR REPLACE FILE FORMAT cricket.land.cricket_json_formatCRICKET.LAND.MY_STAGE
    type = json
    null_if = ('\\n','null','')
    strip_outer_array = true
    comment = 'Json file format with outer strip array flag true';

--create an internal stage in schema "land"
CREATE OR REPLACE STAGE cricket.land.my_stage;

--check if there is any file in my_stage of schema "land"CRICKET.LAND.MY_STAGECRICKET.LAND.MY_STAGE
LIST @cricket.land.my_stage;

--quickly check if data is coming correctly or not
SELECT
    t.$1:meta::variant as meta,
    t.$1:info::variant as info,
    t.$1:innings::variant as innings,
    metadata$filename as file_name,
    metadata$file_row_number int,
    metadata$file_content_key text,
    metadata$file_last_modified stg_modified_ts,

    FROM @my_stage/cricket/json/1000887.json (file_format => 'cricket_json_format') t;
