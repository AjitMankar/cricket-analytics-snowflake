create or replace table raw_data (raw_file variant, filename  varchar(100));

create or replace storage integration s3_int 
type= external_stage
storage_provider=s3
enabled=True
storage_aws_role_arn='arn:aws:iam::*******/Snowflake_access'
storage_allowed_locations=('s3://******/Cricket Analytics/')

describe storage integration s3_int  
create or replace storage integration s3_int 
type= external_stage
storage_provider=s3
enabled=True
storage_aws_role_arn='arn:aws:iam::******:role/Snowflake_access'
storage_allowed_locations=(''s3://*******/Cricket Analytics/')
--storage_blocked_locations 

create or replace stage s3_ext_stage
storage_integration=s3_int
FILE_FORMAT = (TYPE = JSON)
url = 's3://****/Cricket Analytics/'

show stages;
select * from @s3_ext_stage
create or replace pipe s3_pipe auto_ingest=True as 
COPY INTO raw_data
  from (select $1 , metadata$filename as filename from @s3_ext_stage)
on_error=continue

select  system$pipe_status('s3_pipe')
select $1 , metadata$filename as filename from @s3_ext_stage

show pipes 

select * from RAW.raw_data

create or replace stream stream_raw_data on table RAW.raw_data
append_only=TRUE

show streams
stream_raw_data
select * from stream_raw_data

create or replace table raw.default_powerplays 
(match_type varchar(10),
start_over int ,
end_over int 
);
insert into raw.default_powerplays values ('ODI',1,10),('T20',1,6)
select * from raw.default_powerplays;
