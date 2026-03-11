
alter task dw.task_raw_data resume 
alter task dw.task_stg_teams resume 
alter task dw.task_stg_players resume 
alter task dw.task_stg_match resume 
alter task dw.TASK_STG_MATCH_INNINGS resume 

--staging table to insert raw data
select * from staging.stg_raw_data;
select * from raw.stream_raw_data

create or replace table staging.stg_raw_data like RAW.raw_data;

CREATE or replace TASK dw.task_raw_data
  WAREHOUSE = COMPUTE_WH
  SCHEDULE = '1 MINUTE'
  when system$stream_has_data('raw.stream_raw_data') 
  AS 
BEGIN
truncate table staging.stg_raw_data;
insert into staging.stg_raw_data
select raw_file,filename from raw.stream_raw_data;
end;

CREATE or replace TASK dw.task_stg_teams
  WAREHOUSE = COMPUTE_WH
  after dw.task_raw_data
as  
begin
truncate table staging.stg_teams;
insert into staging.stg_teams 
select f0.value::varchar as team_name, raw_file:info.team_type::varchar as team_type
  from staging.stg_raw_data
  ,lateral flatten(raw_file:info.teams) f0
group by all  ;
  end

  --players
CREATE or replace TASK dw.task_stg_players
  WAREHOUSE = COMPUTE_WH
  after dw.task_raw_data
as  
begin  
truncate table staging.stg_players;
insert into staging.stg_players 
select  f1.value::string as player_name,f0.key as team_name
  from staging.stg_raw_data
  ,lateral flatten(raw_file:info.players) f0
  , lateral flatten(f0.value) as f1
  group by all
  ;
end


  --match info
CREATE or replace TASK dw.task_stg_match
  WAREHOUSE = COMPUTE_WH
  after dw.task_raw_data
as  
begin   
truncate table staging.stg_match_info;
insert into staging.stg_match_info
  select raw_file:info.match_type::string as match_type
  ,raw_file:info.gender::string as gender
  ,raw_file:info.season::string as season
  ,raw_file:info.city::string as city
  ,raw_file:info.venue::string as venue
  ,raw_file:info.dates[0]::date as match_date
  ,raw_file:info.teams[0]::string  as team1
  ,raw_file:info.teams[1]::string  as team2
  ,raw_file:info.toss.winner::string as toss_winner
  ,raw_file:info.toss.decision::string as toss_decision
  ,raw_file:info.outcome.winner::string as match_winner
  ,case when raw_file:info.outcome.by.wickets::string is not null then raw_file:info.outcome.by.wickets::string||' wickets' 
    when raw_file:info.outcome.by.runs::string is not null then raw_file:info.outcome.by.runs::string||' runs' 
    else 'no result'
    end as margin
  ,raw_file:info.event.name::string as event_name
  ,raw_file:info.team_type::string as event_type
  ,raw_file:info.player_of_match[0]::string as pom
  ,filename  
from staging.stg_raw_data ;
end

--match innings 
CREATE or replace TASK dw.TASK_STG_MATCH_INNINGS
  WAREHOUSE = COMPUTE_WH
  after dw.task_raw_data
as  
begin   
truncate table staging.stg_match_innings;
insert into staging.stg_match_innings
select f0.index+1 as inning_id
, f.value:over::int+1 as over
,f0.value:team::string as batting_team 
,f1.index+1 as ball_in_over
,f1.value:batter::string as batter
,f1.value:bowler::string as bowler
,f1.value:non_striker::string as non_striker 
,f1.value:runs.batter::int as runs_batter
,OBJECT_keys(f1.value:extras)[0]::string as extra_type
,f1.value:runs.extras::int as runs_extras 
,f1.value:runs.total::int as runs_total
,f1.value:wickets[0].kind::string as dismissal_kind
,f1.value:wickets[0].player_out::string as out_player
,coalesce(ceil(f0.value:powerplays[0].from), start_over) as powerplays_start_over
,coalesce(ceil(f0.value:powerplays[0].to),end_over) as powerplays_end_over
, case when over between powerplays_start_over and powerplays_end_over then 1 else 0 end as is_powerplay
,filename
  from staging.stg_raw_data
  left join raw.default_powerplays on raw_file:info.match_type::string = default_powerplays.match_type
  ,lateral flatten(raw_file:innings) f0
  ,lateral flatten(f0.value:overs) f
  ,lateral flatten(f.value:deliveries) f1;
  end

   

select * from stg_teams;
select * from stg_players;
select * from stg_match_info;
select * from stg_match_innings;


create table test_array
(teams array )
insert into test_array
ARRAY_INSERT
select ARRAY_CONSTRUCT('India','Pak')
select array_agg(distinct team) from test_team
group by 
select * from test_team
create table test_team (team varchar(10))
insert into test_team values ('Pak')
select array_union([])

SELECT ARRAY_CONSTRUCT(1, 2, 3)

  
