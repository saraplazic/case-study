
select * from booking;
select * from cancel_booking_request;
select * from charter;
select * from customer_profile;
select * from decline_booking_request;
select * from package;
select * from reviews;

-- % Cancelled bookings

select round(count(id)/(select count(id) from booking)*100, 2) as PrecentageOfCancellation
from cancel_booking_request;

-- Revenue loss due to cancellations, plus percent

select round(sum(b.commission)) as Total_Cancellation_CashLoss, round(sum(b.commission)/(select sum(commission) from booking where commission is not null)*100,2) as PercentageOfCashLoss
from cancel_booking_request c
left join booking b on (c.booking_id = b.id)
where commission is not null

-- Is there a specific day when cancellations occur?
with DayC as(
select date(date_canceled) ,DayOfWeek(date_canceled) as DaYofCancelation, count(*) as NumOfCancelation
from cancel_booking_request
where date_canceled is not null
group by date(date_canceled)
)
select (case when DaYofCancelation = '1' then 'Sunday'
when DaYofCancelation = '2' then 'Monday'
        when DaYofCancelation = '3' then 'Tuesday'
        when DaYofCancelation = '4' then 'Wednesday'
        when DaYofCancelation = '5' then 'Thursday'
when DaYofCancelation = '6' then 'Friday'
when DaYofCancelation = '7' then 'Saturday' end) as DayOfTheWeek, sum(NumOfCancelation) as NumOfCancelations
from DayC
group by DaYofCancelation
order by sum(NumOfCancelation) desc;

/*the age of people who are cancelling
I'm joining the 'cancellation' table with the 'booking' table, where I retrieve the 'user_id.' 
Then, I connect this with the 'customer profile' table using the 'user_id,' and from there, 
I retrieve the customer's birthday. From the 'cancellation' table, 
I take the date when the client canceled to calculate how old they were at that moment. 
I clean the data from null and illogical values*/

with CalculateAge as (
select
date(c.date_canceled) as dateC,
date(cp.birthday) as dateB,
YEAR(c.date_canceled) - YEAR(cp.birthday) - (DATE_FORMAT(c.date_canceled, '%m%d') < DATE_FORMAT(cp.birthday, '%m%d')) AS age
from cancel_booking_request c
left join booking b on(c.booking_id= b.id)
left join customer_profile cp on(b.user_id =cp.user_id)
where c.date_canceled is not null and cp.birthday is not null and c.initiator = 'customer'
)
select  round(avg(CalculateAge.age))
from CalculateAge
where  CalculateAge.age>0
order by age;

-- the month with the highest cancellation rate
select (case when month(date_canceled)=1 then 'January'
when month(date_canceled)=2 then 'Febuary'
            when month(date_canceled)=3 then 'March'
            when month(date_canceled)=4 then 'April'
            when month(date_canceled)=5 then 'May'
            when month(date_canceled)=6 then 'Jun'
            when month(date_canceled)=7 then 'July'
            when month(date_canceled)=8 then 'August'
            when month(date_canceled)=9 then 'Septemnber'
            when month(date_canceled)=10 then 'October'
            when month(date_canceled)=11 then 'November'
            when month(date_canceled)=12 then 'December' end) as MonthOfYear, count(*) as NumOfC
from cancel_booking_request
where date_canceled is not null
group by month(date_canceled)
order by month(date_canceled)
;

-- which locations had the highest cancellation rates, top 3


with RankedLocationsA as(
select ch.location as Location,  round(count(*) /(select count(*) from cancel_booking_request)*100,2) as PercentageOfTotal,count(*) as NumOfCancealtions, dense_rank() over (order by count(*) desc) as ranks
from cancel_booking_request c
left join booking b on(c.booking_id= b.id)
left join charter ch on (b.charter_id =ch.id)
where ch.Location is not null
group by ch.location
order by NumOfCancealtions desc
)
select RankedLocationsA.Location, RankedLocationsA.NumOfCancealtions,RankedLocationsA.PercentageOfTotal
from RankedLocationsA
where ranks in( 1,2,3);




-- the location with the highest cancellation rate and take the top 4 reasons

with Cancel as(
select reason,count(*) as NumOfReasonNote , dense_rank() over (order by count(*) desc) as ranks
from cancel_booking_request c
left join booking b on(c.booking_id= b.id)
left join charter ch on (b.charter_id =ch.id)
where ch.location = 'Destin' and reason is not null
group by reason
order by NumOfReasonNote desc
)
select reason, round(NumOfReasonNote/(select count(*) from cancel_booking_request c
left join booking b on(c.booking_id= b.id)
left join charter ch on (b.charter_id =ch.id) where ch.location = 'Destin')*100 , 2) as PercentOfTotal
from Cancel
where ranks in (1,2,3,4);

/*In which period, from the destination Destin, 
were there the most cancellations due to bad weather reasons*/

select reason_note,count(*) as NumOfReasonNote
from cancel_booking_request c
left join booking b on(c.booking_id= b.id)
left join charter ch on (b.charter_id =ch.id)
where ch.location = 'Destin' and reason = 'badWeather'  and reason_note IS NOT null and reason_note != '\n'
group by reason_note
order by NumOfReasonNote desc
limit 5;

/*during which period is it most frequent*/

with CancelDestin1 as(
select month(date_canceled) as Month, count(*) as NumOfCancelations, dense_rank() over (order by count(*) desc) as ranks
from cancel_booking_request c
left join booking b on(c.booking_id= b.id)
left join charter ch on (b.charter_id =ch.id)
where ch.location = 'Destin' and reason = 'badWeather'  and reason_note is not null
group by month(date_canceled)
order by NumOfCancelations desc
)
select (case when Month=1 then 'January'
when Month=2 then 'Febuary'
            when Month=3 then 'March'
            when Month=4 then 'April'
            when Month=5 then 'May'
            when Month=6 then 'Jun'
            when Month=7 then 'July'
            when Month=8 then 'August'
            when Month=9 then 'Septemnber'
            when Month=10 then 'October'
            when Month=11 then 'November'
            when Month=12 then 'December' end) AS MonthOfYear
from CancelDestin1
where ranks in (1,2);


/*geographical representation of countries with the least cancellations - the focus here is on country*/

with RankedContries as(
select ch.country as Country, count(*) as NumOfCancealtions, dense_rank() over (order by count(*) asc) as ranks
from cancel_booking_request c
left join booking b on(c.booking_id= b.id)
left join charter ch on (b.charter_id =ch.id)
group by ch.country
order by NumOfCancealtions desc
)
select RankedContries.Country,RankedContries.NumOfCancealtions
from RankedContries
where ranks = 1;


/*geographical representation of countries with the least cancellations - the focus here is on country*/

with RankedContries as(
select ch.country as Country, count(*) as NumOfCancealtions, dense_rank() over (order by count(*) desc) as ranks
from cancel_booking_request c
left join booking b on(c.booking_id= b.id)
left join charter ch on (b.charter_id =ch.id)
group by ch.country
order by NumOfCancealtions desc
)
select RankedContries.Country, RankedContries.NumOfCancealtions
from RankedContries
where ranks = 1;

--the most frequent reasons for client cancellations

select reason, count(*) as NumOfReasons
from cancel_booking_request
where initiator = 'customer' and reason is not null
group by reason
order by NumOfReasons desc;



--for the 'other' reason, extract the 'reason_note'

with OtherReasonCancel as (
select reason_note, count(*) as NumOfCancelation, rank() over ( order by count(*)desc) as ranks
from cancel_booking_request
where reason = 'other' and reason_note is not null
group by reason_note
order by NumOfCancelation desc
)
select reason_note
from OtherReasonCancel
where ranks =1;


--how many days in advance is it booked
with ResBeforeTrip as (
select c.id as CancelID, b.id as BookingId, date(b.date_created), b.trip_date, DATEDIFF(b.trip_date, b.date_created) AS day_difference
from cancel_booking_request c
inner join booking b on (c.booking_id = b.id)
where c.reason ='Other' and c.reason_note = 'Personal'
order by day_difference desc
)
select round(count(*)/(select count(*) from cancel_booking_request where reason ='Other' and reason_note = 'Personal')*100,2) as PercOfCanceledBooking
from ResBeforeTrip
where day_difference > 90
/*-------------------------------------------------------------------------------------------------------
--DECLINE !!!!*/

--the most common reasons for declined bookings

with Declined as (
select reason, count(*) as NumOfReasons, rank() over (order by count(*) desc) as ranks
from decline_booking_request
where reason is not null
group by reason
order by NumOfReasons desc
)
select reason, NumOfReasons, round(numOfReasons/(select count(*) from decline_booking_request)*100,2)
from Declined
where ranks = 1;

/*Now I'm looking at those already booked to see for which date and 
location—first for the date (month and year)*/

with ReasonDeclined as (
select year(b.trip_date) as Year,month(b.trip_date) as Month,count(*) as NumOfDeclined, dense_rank() over (partition by year(b.trip_date) order by count(*)desc) as ranks
from decline_booking_request d
inner join booking b on (d.booking_id = b.id)
where d.reason = 'alreadyBooked'
group by year(b.trip_date),month(b.trip_date)
)
select Year,(case when Month=1 then 'January'
when Month=2 then 'Febuary'
            when Month=3 then 'March'
            when Month=4 then 'April'
            when Month=5 then 'May'
            when Month=6 then 'Jun'
            when Month=7 then 'July'
            when Month=8 then 'August'
            when Month=9 then 'Septemnber'
            when Month=10 then 'October'
            when Month=11 then 'November'
            when Month=12 then 'December' end) as MonthOfYear, NumOfDeclined
from ReasonDeclined
where ranks in (1,2);
 
 
 --then I look at which countries were overbooked
 With CountryDecline as (
 select c.country as Contry, count(*) as NumOfDeclines, dense_rank() over (order by count(*) desc) as ranks
 from decline_booking_request d
 left join booking b on (d.booking_id = b.id)
 left join charter c on (b.charter_id = c.id)
 where d.reason = 'alreadyBooked' and c.country is not null
 group by country
)
select Contry,NumOfDeclines
from CountryDecline
where ranks in (1,2);

 --which locations were overbooked within these two countries
 
  With LocationDecline as (
 select c.country as Contry, c.location as Location,count(*) as NumOfDeclines, dense_rank() over (partition by  c.country  order by count(*) desc) as ranks
 from decline_booking_request d
 left join booking b on (d.booking_id = b.id)
 left join charter c on (b.charter_id = c.id)
 where d.reason = 'alreadyBooked' and c.country in ('United States','Australia') and c.location is not null
 group by c.location )
 select Contry, Location , NumOfDeclines
 from LocationDecline
 where ranks in (1,2);


/*-----------------------------------------------------------------------------------------------*/
-- REVIEWS!!!

/*top three recommended charters, to extract their locations and states they are located in, 
with the percentage of how many people marked them as recommend*/
with Numbers as (
select c.id as ID, count(*) as NumOfRecommendations,c.location as Location,c.country as Country, rank() over (order by count(*) desc)  as ranks
from charter c
inner join booking b on (c.id=b.charter_id )
inner join reviews r on (b.id = r.booking_id)
where r.recommends =1
group by c.id
),
Total as (
select b.charter_id as ID ,count(*) as TotalNUM
from booking b
        group by b.charter_id
)
select n.ID, n.Location, n.Country,n.NumOfRecommendations, t.TotalNUM, round(n.NumOfRecommendations/t.TotalNUM*100,2) as PercentageOfRecommendations
from Numbers n
left join Total t on (n.ID = t.ID)
where n.ranks in (1,2,3)
order by  t.TotalNUM;


/* which bookings generate the highest revenue for the company 
(in terms of what the company relies on, whether it's from a larger number of cheaper bookings 
or a smaller number of more expensive ones)*/


WITH CommLabels as(
select  commission, (case
when commission<=600 then 'Low Commission(less than 600)'
                            when 600<commission and commission<=2000 then 'Medium Commission(between 600 and 2000)'
                            else 'High Commission(more than 2000)' end) as LABEL
from booking
where id is not NULL and commission is not NULL and status = 'done'
)

select LABEL,round(count(*)/(select count(*) from booking where id is not null and status = 'done')*100,2) as PercentOfTotalBookings,
round(sum(commission)/(select sum(commission) from booking where commission is not null and status = 'done')*100,2) as PercentOfTotalRevenue
from CommLabels
group by LABEL
order by count(*) desc;

-- revenue through time

select YEAR(date_created) as theYear,MONTH(date_created) as MonthOfYear,sum(commission) as CommisionSum
from booking
where status = 'done'
group by YEAR(date_created),MONTH(date_created)
order by theYear, MonthOfYear;

/*revenue and review interplay:
Average Revenue per Rating Level*/

select r.rating_overall, round(avg(b.commission),2) as AvgCommission, count(*) as NumOfBookings,
round(count(*)/(select count(*)from booking where id is not null and status = 'done')*100,2) as PecetageOfTotalBookings
from reviews r
inner join booking b on (r.booking_id = b.id)
where r.rating_overall is not null and b.status = 'done'
group by r.rating_overall
order by rating_overall asc


-- total revenue and average rating per month (in relation to the years)

select YEAR(r.date_reviewed) as theYear, MONTH(r.date_reviewed) as MonthOfYear, sum(b.commission) as TotalCommission, round(avg(r.rating_overall),1) as AverageRating
from reviews r
inner join booking b on (r.booking_id = b.id)
where b.status = 'done' and r.rating_overall is not null
group by YEAR(r.date_reviewed), MONTH(r.date_reviewed)
order by theYear,MonthOfYear;

-- average rating of rated bookings in 'done' status and average commission per year

select YEAR(r.date_reviewed) as  theYear, avg(b.commission) as AvgCommission, round(avg(r.rating_overall),2) as AvgRating
from reviews r
inner join booking b on (r.booking_id = b.id)
where b.status = 'done' and r.rating_overall is not null
group by YEAR(r.date_reviewed)
order by theYear;

-- top 10 most visited destinations and their average rating

with Destinations as (
select b.id as BookingID,c.location, c.State, count(*) as NumOfBookings, rank() over(order by count(*)desc) as ranks
    from booking b
    inner join charter c on (b.charter_id = c.id)
    where status = 'done' and c.location is not null
    group by c.location
)
select d.ranks, d.location, round(avg(rating_overall),1) as AverageRating
from Destinations d
left join reviews r on (d.BookingID = r.booking_id)
where d.ranks in(1,2,3,4,5,6,7,8,9,10) and rating_overall is not null
group by d.location
order by d.ranks;

/*------------------------------------
percentage of canceled bookings where the initiator is the captain*/

select round(count(booking_id) / (select count(booking_id) from cancel_booking_request where id is not null) *100,2) as PercentageOfCanceled
from cancel_booking_request
where id is not null and initiator = 'captain';


-- visualization

/*by years and months, the number of reservations per month*/

select year(trip_date) as Year, MONTH(trip_date) AS MonthOfYear, count(*)
from booking
where status= 'done'
group by year(trip_date), MONTH(trip_date)
order by Year,MonthOfYear

-- of the total bookings, what portion went to 'done,' what to 'canceled,' and what to 'rejected'

select status, round(count(*)/(select count(id) from booking where id is not null)*100,2) as PercentageOfTotalBookings
from booking
where id is not null and status is not null
group by status
order by status asc

