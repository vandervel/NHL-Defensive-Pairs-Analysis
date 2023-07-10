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
and with at least 20 total games played. The final dataset will eventually be comprised of players that meet these basic thresholds. */

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

/* Join individual counts dataset with rates data set */

select C.Player,C.Position,C.GP,C.TOI,Goals,Total_Assists,First_Assists,Second_Assists,Total_Points,C.IPP,Shots,C.SH,ixG,iCF,iFF,iSCF,iHDCF,Rush_Attempts,Rebounds_Created,PIM,Total_Penalties,Minor,Major,Misconduct,Penalties_Drawn,Giveaways,Takeaways,Hits,Hits_Taken,Shots_Blocked,TOI_GP,Goals_60,Total_Assists_60,First_Assists_60,Second_Assists_60,Total_Points_60,Shots_60,ixG_60,iCF_60,iFF_60,iSCF_60,iHDCF_60,Rush_Attempts_60,Rebounds_Created_60,PIM_60,Penalties_Drawn_60,Giveaways_60,Takeaways_60,Hits_60,Hits_Taken_60,Shots_Blocked_60 into DefensemanCounts_Rates
from DefensemanCounts C inner join DefensemanRates R on C.Player = R.Player


select * from DefensemanCounts_Rates where Player like 'Quin%'
select * from DefensivePairs where Player_2 like 'Quin%'

--Drop redundant column of Position, as by this point all players in the dataset are defensemen. 

alter table DefensemanCounts_Rates drop column Position

-- In the defensive pairs dataset, Quinn Hughes' name is Quintin Hughes. To facilitate the joining of 
-- the defensive pairs dataset and the individual defensemen dataset, we must update this particular
-- record for the sake of uniformity

update DefensemanCounts_Rates
set Player = 'Quintin Hughes'
where Player like 'Quin%'


/* Obtaining the data type of the "Shots" data feature */ 

select DATA_TYPE
from INFORMATION_SCHEMA.COLUMNS
where TABLE_SCHEMA = 'Hockey' and TABLE_NAME = 'DefensemanCounts_Rates'
and COLUMN_NAME = 'Shots'

select Player, Goals, Total_Assists, Total_Points, Shots
from DefensemanCounts_Rates
order by 5 desc, 1, 2, 3, 4 

/* Percentage of players with more than 100 shots that have
high danger chances created greater than 20. */

/* Begin to investigate the effect of zone starts on player statistics. This an integral part of our analysis.
My original hypothesis was that players who have more defensive starts (and thefore spend more time in the defensive
zone) will have  negatively skewed positive metrics. */


/* Append offensive zone start statistics from defensive pairs data set to 
our individual data set through a join */


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
starts. This is because on-the-fly shifts are typically much shorter and happen due 
to immediate necessity, unlike shifts initiated the offensive and defensive zones,
and are therefore not reflective of a players true deployment. */


/* ----------------------------- */


/* Calculating zone start percentage from the defensive pairs data set and appending it to the each
player in the individual data set. A pair having certain zone start numbers implies that individual
players in that pair will have identical numbers, so we can easily sum up the number of starts,
calculate a percentage, and append it to the individual data set */ 


/* Note: this was originally intended to be the final data set, but upon further analysis it was 
decided that other useful statistics were needed and the final data set was to be updated later */
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




select * from Final_Defensemen_Data
 
select Player, Goals, dense_rank() over (order by Goals desc) as 'rank'
from Final_Defensemen_Data

/* min, max, average and median of defensive zone start percentages */

select max(Def_Start_Pct)
from Final_Defensemen_Data

select avg(Def_Start_Pct)
from Final_Defensemen_Data

select (( select max(Def_Start_Pct) from (select top 50 percent Def_Start_Pct from Final_Defensemen_Data order by Def_Start_Pct) as bottom_half)
+ (select min(Def_Start_Pct) from (select top 50 percent Def_Start_Pct from Final_Defensemen_Data order by Def_Start_Pct) as top_half)
) / 2 as median

/* The series of select statements below are to provide easy access to each dataset while working on the analysis */

select * from Final_Defensemen_Data
select * from on_ice_counts
select * from on_ice_rates

/* Testing whether the DefensivePairs dataset includes defensemen in their rightful position based on whether they shoot right or left.
This statement also tests whether players can be included under both Player and Player_2 columns, depending on the pair. */

select * from DefensivePairs where Player = 'Aaron Ekblad' or Player_2 = 'Aaron Ekblad'
select * from IndividualPlayerRates
select * from DefensemanCounts_Rates


select x.*, y.Team 
from New_Defensemen_data x,
(select distinct a.Player, b.Team
from Final_Defensemen_Data a, DefensivePairs b
where a.Player = b.Player or a.Player = b.Player_2) y
where x.Player = y.Player

/* Joining the superior Natural Stat Trick On Ice data to our data set */



select * into New_Defensemen_data from
(select cr.*, c.HDCA, c.CF1, c.GF1, r.GF_60, r.GA_60,c.HDCF, c.HDCF1, c.xGF, c.xGA, c.Off_Zone_Starts, c.Neu_Zone_Starts, c.Def_Zone_Starts, c.Off_Zone_Start as Off_Zone_Start_Pct, r.SF_60, r.SA_60,
r.SF as 'SF_Pct',
r.HDCF_60, r.HDCA_60, (cast(c.Def_Zone_Starts as float) / (cast(c.Def_Zone_Starts as float) + cast(c.Off_Zone_Starts as float))) * 100 as 'Def_Zone_Start_Pct'
from DefensemanCounts_Rates cr, on_ice_counts c, on_ice_rates r
where cr.Player = c.Player and c.Player = r.Player) as New_Defensemen_data


/* The true final dataset. In addition to the new on-ice statistics we added in the above code,
two scores are assigned to each individual player. One score is a raw score, which is simply the sum of 
various positive and negative statistics. The second score is the adjusted score, for which players have 
their score adjusted based on defensive zone start percentage. Since we discovered through applying linear
regression analysis to the data that high defensive zone start percentage skews both offensive and defensive statistics,
it is necessary to adjust the impact of certain metrics to present a clearer summary of the quality of defensive players. */

select * into Defensemen_Score_data from (

select *, (GF_60 - GA_60 + xGF + GF1 + CF1 + HDCF_60 + SF_60 + Hits_60 + Takeaways_60 - xGA + Shots_Blocked_60 - Giveaways_60 - SA_60 - HDCA_60) as raw_score,
case
	when Def_Zone_Start_Pct >= 50 and Def_Zone_Start_Pct < 60 then (1.2 * GF1 + 1.2 *Shots_Blocked_60 - 0.9 * GA_60 + 1.2 * GF_60 + 1.1 * xGF + 1.4 * CF1 + HDCF_60 + 1.3 * SF_60 + Hits_60 + 1.3 *HDCF1 + Takeaways_60 - 0.9 * xGA - 0.9 * Giveaways_60 - 0.7 * SA_60 -  0.9 * HDCA_60)
	when Def_Zone_Start_Pct >= 60 then ( 1.3 * GF1 + 1.3 * Shots_Blocked_60 + 1.4 * HDCF1 + 1.3 * GF_60 - 0.8 * GA_60 + 1.2 * xGF + 1.5 * CF1 + HDCF_60 + 1.4 * SF_60 + Hits_60 + Takeaways_60 -  xGA - 0.8 * Giveaways_60 -  SA_60 -  0.8 * HDCA_60)
else (Shots_Blocked_60 + GF1 + GF_60 - GA_60 + xGF + CF1 + HDCF_60 + SF_60 + Hits_60 + Takeaways_60 - xGA - Giveaways_60 - SA_60 - HDCA_60)
end as adj_score
from New_Defensemen_data

) as Defensemen_Score_data

select * from New_Defensemen_data

select * into pairs_with_scores_unadj from

(select concat(a.Player, ' ', b.Player) as pair, a.raw_score + b.raw_score as score
from Defensemen_Score_data a, Defensemen_Score_data b 
where a.Player != b.Player) as pairs_with_scores




select * into pairs_with_scores_1 from

(select concat(a.Player, ' ', b.Player) as pair, a.adj_score + b.adj_score as score
from Defensemen_Score_data a, Defensemen_Score_data b 
where a.Player != b.Player) as pairs_with_scores





/* Get ranking of pairs by their respective unadjusted scores */

select * from pairs_with_scores_unadj
where pair in
(select concat(Player, ' ', Player_2) from DefensivePairs)
order by score desc

/* Get ranking of pairs by their respective adjusted score (players with over 50% of starts in 
the defensive zone have the impact of their negative stats reduced by 0.6, and players
with over 60% of starts in the defensive zone have the impact of their negative
stats reduced by 0.5) */

select * from pairs_with_scores_1
where pair in
(select concat(Player, ' ', Player_2) from DefensivePairs)
order by score desc
