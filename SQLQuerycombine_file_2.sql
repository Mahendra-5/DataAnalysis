USE [Cyclists]
GO

/****** Object:  Table [dbo].[combined_file_2]    Script Date: 3/1/2024 2:44:03 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[combined_file_2](
	[ride_id] [nvarchar](50) NULL,
	[rideable_type] [nvarchar](50) NULL,
	[started_at] [datetime2](7) NULL,
	[ended_at] [datetime2](7) NULL,
	[start_station_name] [nvarchar](max) NULL,
	[start_station_id] [nvarchar](50) NULL,
	[end_station_name] [nvarchar](max) NULL,
	[end_station_id] [nvarchar](50) NULL,
	[start_lat] [float] NULL,
	[start_lng] [float] NULL,
	[end_lat] [float] NULL,
	[end_lng] [float] NULL,
	[member_casual] [nvarchar](50) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO


-- Take a look at the data 
select * from dbo.combined_file_2 -- 3474291 rows

-- We have to find null values to get accurate results
select * 
from 
 dbo.combined_file_2
where
 end_lng is null or
 ride_id is null or
 rideable_type is null or
 started_at is null or
 ended_at is null or
 start_station_name is null or
 start_station_id is null or
 end_station_name is null or
 end_station_id is null or
 start_lat is null or
 start_lng is null or
 end_lat is null or
 member_casual is null

 --Therefore there are NULL values in start_station_name, end_station_name, start_station_id,
 --end_station_id. Lets replace them with 'NA'. We are leaving end_lat and end_lng because
 --the columns are in float type.
 
select sum(case when start_station_name is null then 1 end) as start_stat_null, 
	   sum(case when start_station_id is null then 1 end) as start_id_null,	
	   sum(case when end_station_name is null then 1 end) as end_stat_null, 
	   sum(case when end_station_id is null then 1 end) as end_id_null,
	   count(*) as total
from dbo.[combined_file_2]

-- from the above code we can say that we cannot import station_id number to start_station_name

update dbo.combined_file_2
set start_station_name = case when start_station_name is null then 'NA' else start_station_name end,
	start_station_id = case when start_station_id is null then 'NA' else start_station_id end,
    end_station_name = case when end_station_name is null then 'NA' else end_station_name end,
	end_station_id = case when end_station_id is null then 'NA' else end_station_id end
where start_station_name is null
	  or start_station_id is null
	  or end_station_name is null
	  or end_station_id is null

-- Lets check if the data is updated

select* from dbo.combined_file_2
where start_station_name is null or end_station_name is null

--Let us see all the data types of all columns

use Cyclists;
go
select
	COLUMN_NAME,
    DATA_TYPE
from 
    INFORMATION_SCHEMA.COLUMNS
where 
    TABLE_NAME = 'combined_file_2';

-- In order to find out which rider spent more time we have to find the difference
-- between the columns started_at and ended_at which are in datetime2 datatype. 

alter table dbo.[combined_file_2]
add DayDiff int,
	HrDiff int,
    MinDiff int,
    SecDiff int

update dbo.[combined_file_2]
set DayDiff = datediff(day, started_at, ended_at),
	HrDiff = datediff(hour, started_at, ended_at),
    MinDiff = datediff(minute, started_at, ended_at) % 60,
    SecDiff = datediff(second, started_at, ended_at) % 60

-- We can find that there are few zeroes in the DayDifference, HoursDifference,MinutesDifference and 
-- SecondsDifference if we run the below query we can see where HoursDifference,MinutesDifference and SecondsDifference
-- are all zeroes. Therefore that data is not important because the rider did not use the bicycle for even 1 second

select * from dbo.[combined_file_2]
where DayDiff = 0 and HrDiff = 0 and MinDiff = 0 and SecDiff =0

-- We need to delete the rows where HoursDifference,MinutesDifference and SecondsDifference are all zeroes
-- because there is no use where the rider did not even use the bicycle for even 1 minute.

delete from dbo.[combined_file_2]
where DayDiff = 0 and HrDiff = 0 and MinDiff = 0 and SecDiff =0

-- checking coordinates columns
select * from dbo.[combined_file_2] where start_lat is null or start_lng is null or end_lat is null or end_lng is null 
-- 4818 rows are there 


-- There are null values in columns end_lat and end_lng. So since we cannot
-- give 'NA' lets assign 1000 for null values.

update dbo.combined_file_2
set end_lat = 1000, end_lng = 1000
where end_lat is null and end_lat is null

--4818 rows effected

-- Now let's find the distance between coordinates by creating a function 
-- and using the Haversine formula.

CREATE FUNCTION dbo.Calc_Dist (@lat1 as FLOAT,@lon1 as FLOAT,@lat2 as FLOAT,@lon2 as FLOAT)
RETURNS FLOAT
AS
BEGIN
    DECLARE @R FLOAT;
    DECLARE @delta_lat FLOAT;
    DECLARE @delta_lon FLOAT;
    DECLARE @a FLOAT;
    DECLARE @c FLOAT;

    SET @R = 3958.8; -- Earth radius in miles
    SET @lat1 = RADIANS(@lat1);
    SET @lon1 = RADIANS(@lon1);
    SET @lat2 = RADIANS(@lat2);
    SET @lon2 = RADIANS(@lon2);

    SET @delta_lat = @lat2 - @lat1;
    SET @delta_lon = @lon2 - @lon1;

    SET @a = SIN(@delta_lat / 2) * SIN(@delta_lat / 2) + COS(@lat1) * COS(@lat2) * SIN(@delta_lon / 2) * SIN(@delta_lon / 2);
    SET @c = 2 * ATN2(SQRT(@a), SQRT(1 - @a));

    RETURN @R * @c; -- Distance in kilometers
END;
GO

alter table dbo.combined_file_2
add distMi float 

update dbo.[combined_file_2]
set distMi = dbo.caldist(start_lat, start_lng, end_lat, end_lng)

-- 3473411 rows affected and there are 3473411 so every row is updated

select count(*) from dbo.combined_file_2 where distMi > 8000 -- checking the no# of rows 
-- where we entered 1000 in columns end_lat and end_lng. Previously we got 4818
-- and here also we got 4818.


select start_station_name, count(*) as popular_station -- popular start_station_name (Streeter Dr & Grand Ave)
from dbo.combined_file_2
group by start_station_name
order by popular_station desc


select end_station_name, count(*) as popular_station -- popular end_station_name (Streeter Dr & Grand Ave)
from dbo.combined_file_2
group by end_station_name
order by popular_station desc