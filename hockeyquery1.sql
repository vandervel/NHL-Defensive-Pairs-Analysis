select * from DefensivePairs

select * 
from DefensivePairs
where TOI > 100

/* Preliminary queries and basic analysis */

select count(*) from DefensivePairs

select *
from DefensivePairs
where Player_2 = 'Cale Makar'

select Player, Player_2, (cast(HDCA as int) / TOI) * 60 as 'HDCA per 60 mins'
from DefensivePairs
where Team = 'VAN' and TOI > 100
order by [HDCA per 60 mins] desc

select * from DefensivePairs

select * from dbo.IndividualPlayerRates

/* Changing the database name */

alter database DefensivePairs
set single_user with rollback immediate
alter database DefensivePairs modify name=Hockey

alter database Hockey
set multi_user with rollback immediate

/* Basic analysis */

select  Player, Takeaways, Giveaways, Takeaways-Giveaways as 'difference'
from IndividualCounts
where TOI > 500 and GP >= 60 and Position = 'D' and Giveaways < Takeaways
order by 'difference' desc 


select * from IndividualCounts
where Position = 'D' and GP = 1
order by TOI desc


select Player
from IndividualCounts
where Position = 'D' and TOI = (select max(TOI) from IndividualCounts where GP = 1 and Position = 'D')


/* Using new column in where clause */

select Player, (TOI / GP) as IceTimePerGame
from IndividualCounts
where Position = 'D' and GP > 30 and (TOI/GP) > 20
order by IceTimePerGame desc


/* Using CTE (common table expression) */

with IceTimeIncluded as

(select Player, Position, (TOI/GP) as IceTimePerGame
from IndividualCounts)

select avg(IceTimePerGame)
from IceTimeIncluded
where IceTimePerGame > 20 and Position = 'D'
order by IceTimePerGame desc

select * from IndividualCounts

select * from DefensivePairs
where Def_Zone_Starts > 2 * Off_Zone_Starts

select * from IndividualCounts
select * from IndividualPlayerRates

select *
from IndividualCounts c inner join IndividualPlayerRates r on c.Player = r.Player

alter table IndividualCounts
add TOIperGame int not null default 0


alter table IndividualCounts drop column TOIperGame

/* Combining the counts dataset and the rates dataset for defensemen */


select ind.*, rates.TOI_GP
from IndividualCounts ind inner join IndividualPlayerRates rates on ind.Player = rates.Player
where ind.Position = 'D' and rates.TOI_GP >= 15


/* Above and below queries are equivalent */



select i.*, (i.TOI / i.GP) as TOIperGame
from IndividualCounts i
where i.Position = 'D' and i.TOI >= 60 and (i.TOI/i.GP) >= 10 and i.GP >= 20 

/* Removing irrelevant columns */

alter table IndividualCounts drop column Faceoffs

alter table IndividualCounts drop column Faceoffs_Won
alter table IndividualCounts drop column Faceoffs_Lost

alter table IndividualCounts drop column Team

/* Create new table of per-60-minutes-rates for all defensemen with at least 60 total minutes played, at least 10 minutes per game,
and with at least 20 total games played. This will be the final dataset for individual defensemen */

select * into DefensemanRates from
(select i.*
from IndividualPlayerRates i
where i.Position = 'D' and i.TOI >= 60 and TOI_GP >= 10 and i.GP >= 20) as DefensemanRates

select * from DefensemanRates

/* Drop irrelevant columns */
alter table IndividualPlayerRates drop column Team, Total_Penalties_60, Minor_60, Major_60, Misconduct_60, Faceoffs_Won_60, Faceoffs_Lost_60, Faceoffs


/* top 10 defensemen by average time on ice */

select top 10 Player, TOI_GP
from DefensemanRates
order by TOI_GP desc


select Player, Total_Assists_60, First_Assists_60, Second_Assists_60,  abs(First_Assists_60 - Second_Assists_60) as assist_difference
from DefensemanRates
order by First_Assists_60 desc,assist_difference desc

select * from DefensivePairs



select * from IndividualCounts
select * from IndividualPlayerRates

select * into DefensemanCounts from 
(select i.* from IndividualCounts i
where i.Position = 'D' and i.TOI >= 60 and (i.TOI/i.GP >= 10) and i.GP >= 20) as DefensemanCounts



select C.Player,C.Position,C.GP,C.TOI,Goals,Total_Assists,First_Assists,Second_Assists,Total_Points,C.IPP,Shots,C.SH,ixG,iCF,iFF,iSCF,iHDCF,Rush_Attempts,Rebounds_Created,PIM,Total_Penalties,Minor,Major,Misconduct,Penalties_Drawn,Giveaways,Takeaways,Hits,Hits_Taken,Shots_Blocked,TOI_GP,Goals_60,Total_Assists_60,First_Assists_60,Second_Assists_60,Total_Points_60,Shots_60,ixG_60,iCF_60,iFF_60,iSCF_60,iHDCF_60,Rush_Attempts_60,Rebounds_Created_60,PIM_60,Penalties_Drawn_60,Giveaways_60,Takeaways_60,Hits_60,Hits_Taken_60,Shots_Blocked_60 into DefensemanCounts_Rates
from DefensemanCounts C inner join DefensemanRates R on C.Player = R.Player


select * from DefensemanCounts_Rates where Player like 'Quin%'
select * from DefensivePairs where Player_2 like 'Quin%'

--Drop redundant column of Position (All players in dataset are defensemen anyway)

alter table DefensemanCounts_Rates drop column Position

-- In the defensive pairs dataset, Quinn Hughes' name is Quintin Hughes. To facilitate the joining of 
-- the defensive pairs dataset and the individual defensemen dataset, we must update this particular
-- record for the sake of uniformity

update DefensemanCounts_Rates
set Player = 'Quintin Hughes'
where Player like 'Quin%'


select DATA_TYPE
from INFORMATION_SCHEMA.COLUMNS
where TABLE_SCHEMA = 'Hockey' and TABLE_NAME = 'DefensemanCounts_Rates'
and COLUMN_NAME = 'Shots'

select Player, Goals, Total_Assists, Total_Points, Shots
from DefensemanCounts_Rates
order by 5 desc, 1, 2, 3, 4 

/* Percentage of players with more than 100 shots that have
high danger chances created greater than 20. */


select
((select count(*)
from DefensemanCounts_Rates
where iHDCF > 20 and Shots > 30) 
*
(select count(*)
from DefensemanCounts_Rates
where Shots > 30)) / 100.0 as hdcf_percentage

select sum(Off_Zone_Starts) from DefensivePairs 
group by Player


select n.Player_2,  sum(cast(Off_Zone_Starts as int))
from DefensemanCounts_Rates m inner join DefensivePairs n on m.Player = n.Player
group by n.Player_2

/* ------------------------------------------------ */


select * from IndividualCounts
select * from DefensemanCounts
select * from DefensemanCounts_Rates
/* Joining zone start statistics from defensive pairs data to individual player data, as well
as creating columns for percentages of starts in each respective zone, while excluding on-the-fly
starts. This is because on-the-fly shifts are typically much shorter than shifts initiated in other
zones, and are not reflective of a players true deployment. */


/* ----------------------------- */


/* The "main" query. This is the query that will define what our final dataset will look like */
select * into Final_Defensemen_Data from 

(
select ind.*, B.Off_Zone_Starts, B.Neu_Zone_Starts, B.Def_Zone_Starts, B.On_The_Fly_Starts, cast(B.Off_Zone_Starts as float) / (cast(B.Off_Zone_Starts as float) + cast(B.Neu_Zone_Starts as float) + 
cast(B.Def_Zone_Starts as float) ) * 100 as Off_Start_Pct, cast(B.Def_Zone_Starts as float) / (cast(B.Off_Zone_Starts as float) + cast(B.Neu_Zone_Starts as float) + 
cast(B.Def_Zone_Starts as float) ) * 100 as Def_Start_Pct, cast(B.Neu_Zone_Starts as float) / (cast(B.Off_Zone_Starts as float) + cast(B.Neu_Zone_Starts as float) + 
cast(B.Def_Zone_Starts as float) ) * 100 as Neu_Start_Pct

from DefensemanCounts_Rates ind inner join 


(select Player, sum(Off_Starts) as Off_Zone_Starts, sum(Neu_Starts) as Neu_Zone_Starts, sum(Def_Starts) as Def_Zone_Starts, sum(Fly_Starts) as On_The_Fly_Starts from 

(select Player, sum(cast(Off_Zone_Starts as int)) as Off_Starts, sum(cast(Neu_Zone_Starts as int)) as Neu_Starts, sum(cast(Def_Zone_Starts as int)) as Def_Starts,
	sum(cast(On_The_Fly_Starts as int)) as Fly_Starts
from DefensivePairs
group by Player

union

select Player_2, sum(cast(Off_Zone_Starts as int)) as Off_Starts, sum(cast(Neu_Zone_Starts as int)) as Neu_Starts, sum(cast(Def_Zone_Starts as int)) as Def_Starts,
	sum(cast(On_The_Fly_Starts as int)) as Fly_Starts
from DefensivePairs
group by Player_2) A



group by A.Player) B on ind.Player = B.Player
) as Final_Defensemen_Data



/* ----------------------------- */




select ind.*, def.Off_Zone_Starts, def.Neu_Zone_Starts, def.Def_Zone_Starts, def.On_The_Fly_Starts
from IndividualCounts ind inner join DefensivePairs def on (ind.Player = def.Player or ind.Player = def.Player_2)


/* View final dataset */

select * from Final_Defensemen_Data
 
















