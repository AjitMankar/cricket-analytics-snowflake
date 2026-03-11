alter task dw.task_teams resume 
alter task dw.task_players resume 
alter task dw.task_match_info resume 
alter task dw.task_match_innings resume 
alter task dw.TASK_STG_MATCH_INNINGS resume 



CREATE or replace TASK dw.task_teams
  WAREHOUSE = COMPUTE_WH
  after dw.task_stg_teams,dw.task_stg_players,dw.task_stg_match,dw.task_stg_match_innings
as  CRICKET_ANALYTICS.DW.TASK_MATCH_INFO
insert into teams  
select seq_teams.nextval as team_id, * 
from staging.stg_teams
where team_name not in (select team_name from dw.teams);


CREATE or replace TASK dw.task_players
  WAREHOUSE = COMPUTE_WH
  after dw.task_teams
as  
MERGE INTO dw.players AS target
USING (select p.player_name,array_agg(distinct t.team_id) as teams
from staging.stg_players p
inner join teams t on p.team_name=t.team_name
group by 1
) AS source
ON target.player_name = source.player_name
WHEN MATCHED THEN
    UPDATE SET
        teams = ARRAY_DISTINCT(ARRAY_CAT(target.teams, source.teams))
WHEN NOT MATCHED THEN
    INSERT (player_id, player_name, teams)
    VALUES (seq_players.nextval, source.player_name, source.teams);



CREATE or replace TASK dw.task_match_info
  WAREHOUSE = COMPUTE_WH
  after dw.task_players
as  
insert into dw.match_info 
select seq_matches.nextval as match_id, MATCH_TYPE, GENDER, SEASON, CITY, VENUE, MATCH_DATE
,t1.team_id as TEAM1_id
,t2.team_id as TEAM2_id
,t3.team_id as TOSS_WINNER_id
,TOSS_DECISION
,t4.team_id as MATCH_WINNER_id
,MARGIN, EVENT_NAME, EVENT_TYPE
,p.player_id as POM_id
,mi.filename
from staging.stg_match_info mi
inner join dw.teams t1 on mi.team1=t1.team_name
inner join dw.teams t2 on mi.team2=t2.team_name
inner join dw.teams t3 on mi.toss_winner=t3.team_name
left join dw.teams t4 on mi.match_winner=t4.team_name
left join dw.players p on mi.pom=p.player_name
where mi.filename not in (select filename from dw.match_info)
;
CREATE or replace TASK dw.task_match_innings
  WAREHOUSE = COMPUTE_WH
  after dw.task_match_info
as  
insert into dw.match_innings 
select mi.match_id, INNING_ID, OVER, t1.team_id as BATTING_TEAM_id, BALL_IN_OVER, BATTER, BOWLER, NON_STRIKER, RUNS_BATTER, EXTRA_TYPE, RUNS_EXTRAS, RUNS_TOTAL, DISMISSAL_KIND, OUT_PLAYER, IS_POWERPLAY
from staging.stg_match_innings ing 
inner join dw.match_info mi on ing.filename=mi.filename
inner join dw.teams t1 on ing.BATTING_TEAM=t1.team_name
where mi.match_id not in (select match_id from dw.match_innings)





select * from dw.teams;
select * from dw.players;
select *from dw.match_info;
select * from dw.match_innings



SELECT 
    p.PLAYER_ID,
    p.PLAYER_NAME,
    f.value::NUMBER AS TEAM_ID
FROM DW.PLAYERS p,
LATERAL FLATTEN(input => p.TEAMS) f

SELECT
    p.PLAYER_NAME,
    f.value::NUMBER AS TEAM_ID,
    t.TEAM_NAME
FROM DW.PLAYERS p,
LATERAL FLATTEN(input => p.TEAMS) f
JOIN DW.TEAMS t
ON f.value::NUMBER = t.TEAM_ID



