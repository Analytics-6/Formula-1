select * from information_schema.tables where table_schema='public';

select * from seasons; -- 74
select * from status; -- 139	
select * from circuits; -- 77
select * from races where year=2022; -- 1102
select * from drivers; -- 857
select * from constructors; -- 211
select * from constructor_results; -- 12170
select * from constructor_standings; -- 12941
select * from driver_standings; -- 33902
select * from lap_times; -- 538121
select * from pit_stops; -- 9634
select * from qualifying; -- 9575
select * from results; -- 25840
select * from sprint_results; -- 120

1) Identify the country which has produced the most F1 drivers.

select nationality as country, count(1) as no_of_drivers from drivers
group by nationality
order by 2 desc
limit 1

or

select country, no_of_drivers from
(
select nationality as country, count(1) as no_of_drivers,
rank() over(order by count(1) desc) as rank from drivers
group by nationality) x
where x.rank = 1

or

with temp as
(
select nationality as country, count(1) as no_of_drivers,
rank() over(order by count(1) desc) as rank from drivers
group by nationality)
select country, no_of_drivers from temp
where rank = 1


2) Which country has produced the most no of F1 circuits

select country, count(1) as no_of_circuits from circuits
group by country
order by 2 desc
limit 1

or

select country, no_of_circuits from
(select country, count(1) as no_of_circuits,
rank() over(order by count(1) desc) as rank from circuits
group by country) x
where x.rank = 1

or 

with temp as
(select country, count(1) as no_of_circuits,
rank() over(order by count(1) desc) as rank from circuits
group by country)
select country, no_of_circuits from temp
where rank = 1

3) Which countries have produced exactly 5 constructors?

select nationality, count(1) as no_of_constructors from constructors
group by nationality
order by 2 desc
limit 5

or

select nationality, no_of_constructors from
(select nationality, count(1) as no_of_constructors,
rank() over(order by count(1) desc) as rank from constructors
group by nationality) x
where x.rank <= 5

or

with temp as
(select nationality, count(1) as no_of_constructors,
rank() over(order by count(1) desc) as rank from constructors
group by nationality)
select nationality, no_of_constructors from temp
where rank <= 5


4) List down the no of races that have taken place each year
	
select year, count(1) as no_of_races from races
group by year
order by year desc

or 

select distinct year, count(1) as no_of_races from races
group by year
order by 1,2 desc


5) Who is the youngest and oldest F1 driver?

select 
max(case when rn = 1 then forename||' '||surname end) as youngest_driver,
max(case when rn = cnt then forename||' '||surname end) as oldest_driver
from
(
select *,
row_number() over( order by dob) as rn,
count(*) over() as cnt
from drivers) x
where rn = 1 or rn = cnt


6) List down the no of races that have taken place each year 
and mentioned which was the first and the last race of each season.
				   				   
select distinct year,
first_value(name) over(partition by year order by date) as first_race,
last_value(name) over(partition by year order by date
				range between unbounded preceding and unbounded following) as last_race,
count(*) over(partition by year) as no_of_races from races	
order by year desc

7) Which circuit has hosted the most no of races. 
Display the circuit name, no of races, city and country.

select c.name as circuit_name, count(1) as no_of_races,
c.location as city, c.country as country from circuits c 
join races r on r.circuitid = c.circuitid
group by circuit_name, city, country
order by no_of_races desc
limit 1

or 

select circuit_name, city, country ,no_of_races from
(
select c.name as circuit_name, count(1) as no_of_races,
c.location as city, c.country as country,
rank() over(order by count(1) desc) as rank from circuits c 
join races r on r.circuitid = c.circuitid
group by circuit_name, city, country) x
where x.rank = 1

or

with temp as
(
select c.name as circuit_name, count(1) as no_of_races,
c.location as city, c.country as country,
rank() over(order by count(1) desc) as rank from circuits c 
join races r on r.circuitid = c.circuitid
group by circuit_name, city, country)
select circuit_name, city, country ,no_of_races from temp
where rank = 1

or


with temp as
		(select c.name as circuit_name, count(1) no_of_races
		, rank() over(order by count(1) desc) as rank
		from races r
		join circuits c on c.circuitid=r.circuitid
		group by c.name)
	select circuit_name, no_of_races, c.location as city, c.country 
	from circuits c
	join temp on temp.circuit_name=c.name
	where rank=1


8) Display the following for 2022 season:
Year, Race_no, circuit name, driver name, driver race position, driver race points, flag to indicate if winner
, constructor name, constructor position, constructor points, , flag to indicate if constructor is winner
, race status of each driver, flag to indicate fastest lap for which driver, total no of pit stops by each driver

select r.year, r.raceid, r.name as circuit_name, 
concat(d.forename,' ',d.surname) as drivers_name, ds.position as driver_race_position,
ds.points as race_points,
case when ds.position = 1 then 'winner' end as winner_flag,
c.name as constructor_name, cs.position as constructor_position, 
cs.points as constructor_points,
case when cs.position = 1 then 'team_winner' end as team_flag, s.status,
case when fst.fastest_lap = res.fastestlap then 'fastest_lap' end as fastest_lap_flag, no_of_pit_stops from races r
join driver_standings ds on ds.raceid = r.raceid
join drivers d on d.driverid = ds.driverid
join constructor_standings cs on cs.raceid = r.raceid
join constructors c on c.constructorid = cs.constructorid
join results res on res.raceid = r.raceid and res.driverid = d.driverid and res.constructorid = c.constructorid
join status s on s.statusid = res.statusid
left join (select raceid, min(fastestlap) as fastest_lap from results
group by raceid) fst on fst.raceid = r.raceid
left join (select raceid, driverid, count(1) as no_of_pit_stops from pit_stops
group by raceid, driverid) stp on stp.raceid = r.raceid and stp.driverid = d.driverid
where r.year = 2022


9) List down the names of all F1 champions and the no of times they have won it.

with cte as
(
select r.year, concat(d.forename,' ',d.surname) as driver_name, sum(res.points) as total_points,
rank() over(partition by r.year order by sum(res.points) desc) as rank
from races r
join driver_standings ds on ds.raceid=r.raceid
join drivers d on d.driverid=ds.driverid
join results res on res.raceid=r.raceid and res.driverid=ds.driverid
group by r.year, driver_name, res.driverid
),
cte_rank as
(
select * from cte where rank = 1
)
select driver_name as F1_Champions, count(1) as no_of_times_they_won
from cte_rank
group by driver_name
order by 2 desc


10) Who has won the most constructor championships

with cte as
(
select r.year, c.name as constructor_name, sum(res.points) as total_points,
rank() over(partition by year order by sum(res.points) desc) as rank from races r
join constructor_standings cs on cs.raceid = r.raceid
join constructors c on c.constructorid = cs.constructorid
join constructor.results res on res.constructorid = c.constructorid and res.raceid = r.raceid
group by r.year, c.name, res.constructorid),
cte_rank as
(select * from cte where rank = 1)
select constructor_name as team_name, count(1) as no_of_championships from cte_rank
group by team_name
order by 2 desc
limit 1

11) How many races has India hosted?

select c.name as circuit_name, c.country as host_country, count(1) as no_of_times_hosted from circuits c
join races r on c.circuitid = r.circuitid
where c.country  = 'India'
group by c.name, c.country
order by 3 desc

12) Identify the driver who won the championship or was a runner-up. Also display the
team they belonged to.

select year, driver_name, constructor_name,
case when rank = 1 then 'winner' else 'runner' end as flag
from
(
select r.year, concat(d.forename,' ',d.surname) as driver_name, c.name as constructor_name, sum(res.points) as total_points,
rank() over(partition by year order by sum(res.points) desc) as rank
from races r
join driver_standings ds on ds.raceid = r.raceid
join drivers d on d.driverid = ds.driverid
join results res on res.driverid = d.driverid and res.raceid = r.raceid
join constructors c on c.constructorid = res.constructorid
where r.year >= 2020
group by r.year, driver_name, res.driverid, c.name
) x
where x.rank <= 2

or

with cte as
(
select r.year, concat(d.forename,' ',d.surname) as driver_name, c.name as constructor_name, sum(res.points) as total_points,
rank() over(partition by year order by sum(res.points) desc) as rank
from races r
join driver_standings ds on ds.raceid = r.raceid
join drivers d on d.driverid = ds.driverid
join results res on res.driverid = d.driverid and res.raceid = r.raceid
join constructors c on c.constructorid = res.constructorid
where r.year >= 2020
group by r.year, driver_name, res.driverid, c.name
)
select year, driver_name, constructor_name,
case when rank = 1 then 'winner' else 'runner' end as flag
from cte
where rank <= 2


13. Display the top 10 drivers with most wins.

select driver_name, most_wins from
(
select ds.driverid, d.forename||' '||d.surname as driver_name, count(1) as most_wins,
rank() over(order by count(1) desc) as rank from drivers d
join driver_standings ds on ds.driverid = d.driverid
where ds.position = 1
group by driver_name, ds.driverid
) x
where x.rank <= 10

or

with cte as
(
select ds.driverid, d.forename||' '||d.surname as driver_name, count(1) as most_wins,
rank() over(order by count(1) desc) as rank from drivers d
join driver_standings ds on ds.driverid = d.driverid
where ds.position = 1
group by driver_name, ds.driverid
)
select driver_name, most_wins from cte
where rank <= 10

or

select ds.driverid, d.forename||' '||d.surname as driver_name, count(1) as most_wins,
rank() over(order by count(1) desc) as rank from drivers d
join driver_standings ds on ds.driverid = d.driverid
where ds.position = 1
group by driver_name, ds.driverid
limit 10

14. Display the top 3 constructors of all time.

select cs.constructorid, c.name as constructor_name, count(1) as most_wins,
rank() over(order by count(1) desc) as rank from constructors c
join constructor_standings cs on cs.constructorid = c.constructorid
where cs.position = 1
group by c.name, cs.constructorid
limit 3

or

select constructor_name, most_wins from 
(select cs.constructorid, c.name as constructor_name, count(1) as most_wins,
rank() over(order by count(1) desc) as rank from constructors c
join constructor_standings cs on cs.constructorid = c.constructorid
where cs.position = 1
group by c.name, cs.constructorid) x
where x.rank <= 3

or

with cte as
(select cs.constructorid, c.name as constructor_name, count(1) as most_wins,
rank() over(order by count(1) desc) as rank from constructors c
join constructor_standings cs on cs.constructorid = c.constructorid
where cs.position = 1
group by c.name, cs.constructorid)
select constructor_name, most_wins from cte
where rank <= 3

15) Identify the drivers who have won races with multiple teams.

select driverid, driver_name, string_agg(constructor_name,', ') from
(
select distinct res.driverid as driverid, concat(d.forename,' ',d.surname) as driver_name, c.name as constructor_name 
from results res
join drivers d on res.driverid = d.driverid
join constructors c on c.constructorid = res.constructorid
where res.position = 1
) x
group by driverid, driver_name
having count(1)> 1
order by driverid, driver_name

16) How many drivers have never won any race?

select count(driverid) from drivers 
where driverid not in (select distinct driverid from driver_standings where position = 1)

17) Are there any constructors who never scored a point? if so mention their name and how many races they participated in?

select cres.constructorid, c.name as constructor_name, sum(cres.points) as total_points, 
count(1) as no_of_races
from constructors c
join constructor_results cres on cres.constructorid = c.constructorid
group by cres.constructorid, c.name
having sum(cres.points) = 0
order by 3 desc, 2



18) Mention the drivers who have won more than 50 races

select d.forename||' '||d.surname as driver_name, count(1) as most_wins
from drivers d
join driver_standings ds on ds.driverid = d.driverid
where ds.position = 1
group by driver_name
having count(1) > 50
order by 2 desc


19) Identify the podium finishers of each race in 2022 season

select r.name as race_name, concat(d.forename,' ',d.surname) as driver_name
from drivers d 
join driver_standings ds on ds.driverid = d.driverid
join races r on r.raceid = ds.raceid
where r.year = 2022 and ds.position <= 3
order by r.raceid


20) For 2022 season, mention the points structure for each position. i.e. how many
points are awarded to each race finished position.

with cte as
(
select min(res.raceid) as raceid from results res
join races r on r.raceid = res.raceid
where r.year = 2022)
select r.points, r.position 
from results r
join cte on cte.raceid = r.raceid
where r.points > 0


21) How many drivers participated in 2022 season?

select count(distinct driverid ) as number_of_drivers from driver_standings ds
where raceid in
(
select raceid from races r where r.year = 2022
)


22)  How many races has each of the top 5 constructors won in the last 10 years.

with top_5_teams as
(
select constructorid, constructor_name 
from
(select cs.constructorid as constructorid,c.name as constructor_name, count(1) as no_of_times,
rank() over(order by count(1) desc) as rank 
from constructors c
join constructor_standings cs on c.constructorid = cs.constructorid
where cs.position = 1
group by cs.constructorid, constructor_name
order by 3 desc
) x
where x.rank <= 5
)
select cte.constructorid, cte.constructor_name, coalesce(cs.wins,0) as wins from top_5_teams cte
left join
(select cs.constructorid, count(1) as wins from constructor_standings cs join races r on
r.raceid = cs.raceid
where cs.position = 1 and r.year >= (extract(year from current_date) - 10)
group by cs.constructorid) cs 
on cte.constructorid = cs.constructorid
order by 3 desc

23) Display the winners of every sprint so far in F1

select r.year as race_year, r.name as race_name, concat(d.forename,' ',d.surname) as driver_name 
from sprint_results s
join races r on r.raceid = s.raceid
join drivers d on d.driverid = s.driverid
where s.position = 1
order by 1,2 

24) Find the driver who has the most no of Did Not Qualify during the race.

select r.driverid as driver_id, concat(d.forename,' ',d.surname) as driver_name , 
count(1) as most_times_disqualified, 
rank() over(order by count(1) desc) as rank
from results r
join drivers d on d.driverid = r.driverid
join status s on r.statusid = s.statusid
where status = 'Did not qualify'
group by r.driverid, driver_name
limit 1

or

select driver_id, driver_name, most_times_disqualified
from
(select r.driverid as driver_id, concat(d.forename,' ',d.surname) as driver_name , 
count(1) as most_times_disqualified, 
rank() over(order by count(1) desc) as rank
from results r
join drivers d on d.driverid = r.driverid
join status s on r.statusid = s.statusid
where status = 'Did not qualify'
group by r.driverid, driver_name) x
where x.rank = 1

or

with cte as
(
select r.driverid as driver_id, concat(d.forename,' ',d.surname) as driver_name , 
count(1) as most_times_disqualified, 
rank() over(order by count(1) desc) as rank
from results r
join drivers d on d.driverid = r.driverid
join status s on r.statusid = s.statusid
where status = 'Did not qualify'
group by r.driverid, driver_name
)
select driver_id, driver_name, most_times_disqualified
from cte
where rank = 1

 
25) During the last race of 2022 season, identify the drivers who did not finish the race
and the reason for it.	


select concat(d.forename,' ',d.surname) as driver_name, s.status as reason
from results r
join drivers d on r.driverid = d.driverid
join status s on s.statusid = r.statusid
where r.raceid = (select max(raceid) from races where year = 2022)
and r.statusid <> 1

26) What is the average lap time for each F1 circuit. Sort based on least lap time.
	*** There may be missing lap time data for some circuits.

select c.circuitid as circuit_id, c.name as circuit_name, c.location as city, c.country as country, avg(lt.time) as avg_lap_time
from circuits c
left join races r on c.circuitid = r.circuitid
left join lap_times lt on r.raceid = lt.raceid
group by c.circuitid, c.name, c.location, c.country
order by avg_lap_time 


27) Who won the drivers championship when India hosted F1 for the first time?

with x as
(
select r.year, concat(d.forename,' ',d.surname) as driver_name, sum(res.points) as total_points,
rank() over(partition by r.year order by sum(res.points) desc) as rank 
from races r
join driver_standings ds on ds.raceid = r.raceid
join drivers d on d.driverid = ds.driverid
join results res on res.raceid=r.raceid and res.driverid=ds.driverid
where r.year in (2011, 2012, 2013)
group by r.year, driver_name
),
y as
(
select * from x where rank = 1
),
z as
(
select min(year) as first_year from races where circuitid in 
(select circuitid from circuits where country = 'India')
)
select year, driver_name from y
where year = (select first_year from z)


28) Which driver has done the most lap time in F1 history?

select driver_name, most_lap_time
from
(
select lt.driverid, concat(d.forename,' ',d.surname) as driver_name, sum(lt.time) as most_lap_time,
rank() over(order by sum(lt.time) desc) as rank
from lap_times lt
join drivers d on d.driverid = lt.driverid
group by lt.driverid, driver_name
) x
where x.rank = 1


29) Name the top 3 drivers who have got the most podium finishes in F1 (Top 3 race
finishes)

select driver_name, no_of_podium_finishes
from
(
select ds.driverid as driver_id, concat(d.forename,' ',d.surname) as driver_name, count(1) as no_of_podium_finishes,
rank() over(order by count(1) desc) as rank
from drivers d
join driver_standings ds on ds.driverid = d.driverid
where ds.position <= 3
group by driver_id, driver_name
) x
where x.rank <= 3

30) Which driver has the most pole position (no 1 in qualifying)
    ****Data is missing for some race qualifications
											 											 
select driver_name, no_of_pole_positions
from
(											 
select q.driverid as driver_id, concat(d.forename,' ',d.surname) as driver_name, count(1) as no_of_pole_positions,
rank() over(order by count(1) desc) as rank
from qualifying q
join drivers d on d.driverid = q.driverid
where q.position = 1											 
group by driver_id, driver_name											 
) x
where x.rank = 1

