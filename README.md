### BIKE SHARING DATA ANALYSIS
#### ASK -> PREPARE -> PROCESS -> ANALYZE -> SHARE

### ASK PHASE
**Background:** In 2016, Cyclistic launched a bike-share program in Chicago, which has since grown to 5,824 bikes across 692 stations. The bikes are geotracked and can be unlocked from one station and returned to any other in the system. Initially, Cyclistic's marketing focused on broad consumer segments and flexible pricing plans. Casual riders opt for single-ride or full-day passes, while annual memberships are preferred by Cyclistic members. Financial analysis shows that annual members are more profitable. To drive future growth, Moreno aims to convert casual riders into annual members through targeted marketing strategies. Understanding the differences between these groups and the impact of digital media on marketing tactics is crucial. Moreno's team plans to analyze Cyclistic's historical bike trip data to identify trends.

**Members of team RESPONSIBILITIES:**
- **Director of marketing:** Development of campaigns and initiatives to promote the bike-share program.
- **Analytical team:** Responsible for collecting, analyzing, and reporting data.
- **Executive team:** Decide whether to approve the marketing program.

**Business task:** Building general awareness about whether the company is more profitable or converting casual riders to members is more profitable.
**My task:** How do annual members and casual riders use Cyclistic’s bikes differently?

### PREPARE PHASE
**Data source:** The data is open-source, and all the rights of the data are owned by the City of Chicago. The data is collected and stored by Divvybikes therefore the data is primary data, reliable, original, comprehensive, current, cited. Divvybikes shared the data in zip files which have monthly records of cyclists. One zip file consists of one month’s data in a CSV file format which is structured data. There is data available since 2013 however, I took 2023 to January 2024 cyclist’s data because I need new data for my analysis.

**File organization:**

<img width="200" alt="200145" src="https://github.com/Mahendra-5/DataAnalysis/assets/160994768/c4312400-9e90-4b6f-8956-b5aa4a182b2c">

**Exploring the data:**  
I open the 2023 January CSV file in Excel to explore the data.
**Observations:** 
1. There are a total of 19000 rows and 13 columns.
2. The type of bike used by cyclists is given.
3. Ride ID is given which has all unique values.
4. The start and end times of the trip are given in date-time format.
5. Start station and end station names, IDs, and coordinates are given.
6. Whether the trip is done by a member or casual is also given.
7. Using the filter, I found that there are many blanks in the start and end station’s name and id.

After exploring one CSV file out of 13 I felt that there is a lot of cleaning that needs to be done. So, if we clean the CSV file one after one it will take a lot of time if we clean the files individually. So, let’s combine 6 CSV files into one, name the file as combined_file, and the rest of the CSV files into another file, name it as combined_2. Eventually, we will get two files, and then let’s start cleaning the two files in SQL.

**Program to combine CSV files in Python:**
````py
import pandas as pd
import glob

# Path to the directory containing CSV files
input_path = r'give input path'

# Use glob to get all CSV files in the directory
all_files = glob.glob(input_path + "/*.csv")

# Combine all CSV files into a single DataFrame
combined_df = pd.concat((pd.read_csv(f) for f in all_files), ignore_index=True)

# Specify the path and filename for the combined CSV file
output_file_path = r'give output path'

# Save the combined DataFrame to the specified CSV file
combined_df.to_csv(output_file_path, index=False)
````
### PROCESS PHASE
I used Microsoft SQL Server Management Studio to clean the data using SQL. Firstly, I created a database Cyclists and then I added the two CSV files to clean the data.
**Plan:**
1. Replace all the null values with ‘NA’ where the column data type is text or NVARCHAR. If the column data type is a value, then replace the null value with 1000.
2. Create a new column for how many days, hours, minutes, and seconds to find how much time is spent on each trip.
3. Create a function to find the distance between the coordinates of the start station and the end station. Fill the distance between the coordinates in a new column.
4. Use built-in functions like trim() to maintain the data integrity.
5. Make it useful to create data visuals in PowerBI.

Let’s start coding in SQL.

Take a look at the data
````sql
select * from dbo.combined_file
````
<img width="1158" alt="sa" src="https://github.com/Mahendra-5/DataAnalysis/assets/160994768/41efd85c-3844-4199-9ff1-c6835efe0c2d">

We have to find null values to get accurate results

````sql
select * 
from 
 dbo.combined_file
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
````
Therefore there are NULL values in start_station_name, end_station_name, start_station_id,
and end_station_id. Let's replace them with 'NA'. We are leaving end_lat and end_lng because
the columns are in float type.

````sql
update dbo.combined_file
set start_station_name = 'NA',
     start_station_id = 'NA',
	 end_station_name = 'NA',
	 end_station_id = 'NA'
where start_station_name is null
	  or start_station_id is null
	  or end_station_name is null
	  or end_station_id is null
````
Let's check if the data is updated.
```sql
select* from dbo.combined_file
where start_station_name is null or end_station_name is null
```
It will not return any rows.

Let us see all the data types of all columns.
```sql
use Cyclists;
go
select
	COLUMN_NAME,
    DATA_TYPE
from 
    INFORMATION_SCHEMA.COLUMNS
where 
    TABLE_NAME = 'combined_file';
```
<img width="161" alt="sa1" src="https://github.com/Mahendra-5/DataAnalysis/assets/160994768/93276239-c44e-4855-88e7-d54f4818e79a">

To find out which rider spent more time we have to find the difference
between the columns started_at and ended_at into date and time separately.
```sql
alter table dbo.[combined_file]
add DayDiff int,
	HrDiff int,
    MinDiff int,
    SecDiff int
```
Using datediff function we can find the difference between the date
```sql
update dbo.[combined_file]
set DayDiff = datediff(day, started_at, ended_at),
	HrDiff = datediff(hour, started_at, ended_at),
-- HrDiff means HoursDifference
    MinDiff = datediff(minute, started_at, ended_at) % 60,
-- MinDiff means MinutesDifference
    SecDiff = datediff(second, started_at, ended_at) % 60
-- SecDiff means SecondsDifference  
```
We can find that there are few zeroes in the HoursDifference, MinutesDifference, and SecondsDifference
if we run the below query we can see where HoursDifference, MinutesDifference, and SecondsDifference
are all zeroes. Therefore that data is not important because the rider did not use the bicycle for even 1 second

```sql
select * from dbo.[combined_file]
where DayDiff = 0 and HrDiff = 0 and MinDiff = 0 and SecDiff =0
```
We need to delete the rows where HoursDifference, MinutesDifference and SecondsDifference are all zeroes
because there is no use where the rider did not even use the bicycle for even 1 minute.

```sql
delete from dbo.[combined_file]
where DayDiff = 0 and HrDiff = 0 and MinDiff = 0 and SecDiff =0
```
checking null values in end_lat and end_lng columns
```sql
select * from dbo.[combined_file] where end_lat is null and end_lng is null
```
There are null values in columns end_lat and end_lng. So since we cannot
give 'NA' let's assign 1000 for null values.

```sql
update dbo.combined_file
set end_lat = 1000, end_lng = 1000
where end_lat is null and end_lat is null
```
Now let's find the distance between coordinates by creating a function 
and using the haversine formula.
<img width="362" alt="sa2" src="https://github.com/Mahendra-5/DataAnalysis/assets/160994768/d8bcdced-7007-46a5-bb54-afbae751bfd3">
```sql
CREATE FUNCTION dbo.caldist (@lat1 as FLOAT,@lon1 as FLOAT,@lat2 as FLOAT,@lon2 as FLOAT)
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

    RETURN @R * @c; -- Distance in miles
END;
GO
```
Now create a new column distMi (distance in miles) to update the distance between the coordinates

```sql
alter table dbo.combined_file
add distMi float
```
```sql
update dbo.[combined_file]
set distMi = dbo.caldist(start_lat, start_lng, end_lat, end_lng)
```









