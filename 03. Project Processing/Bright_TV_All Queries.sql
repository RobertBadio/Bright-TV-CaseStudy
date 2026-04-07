--loading dataset 1
select * 
from `workspace`.`default`.`bright_tv_dataset_1` 
limit 100;


--loading dataset 2
select * 
from `workspace`.`default`.`bright_tv_dataset_2` 
limit 100;



--LEFT join of both tables

select *
from `workspace`.`default`.`bright_tv_dataset_1` as A
left join `workspace`.`default`.`bright_tv_dataset_2` as B
on A.userid = B.userid;



-- Data Quality Check: Count NULL and 'None' values per column
SELECT 
  'Name' as column_name,
  COUNT(*) as total_rows,
  SUM(CASE WHEN Name IS NULL OR Name = 'None' THEN 1 ELSE 0 END) as null_or_none_count
FROM workspace.default.bright_tv_dataset_2
UNION ALL
SELECT 
  'Surname',
  COUNT(*),
  SUM(CASE WHEN Surname IS NULL OR Surname = 'None' THEN 1 ELSE 0 END)
FROM workspace.default.bright_tv_dataset_2
UNION ALL
SELECT 
  'Gender',
  COUNT(*),
  SUM(CASE WHEN Gender IS NULL OR Gender = 'None' THEN 1 ELSE 0 END)
FROM workspace.default.bright_tv_dataset_2
UNION ALL
SELECT 
  'Race',
  COUNT(*),
  SUM(CASE WHEN Race IS NULL OR Race = 'None' THEN 1 ELSE 0 END)
FROM workspace.default.bright_tv_dataset_2
UNION ALL
SELECT 
  'Province',
  COUNT(*),
  SUM(CASE WHEN Province IS NULL OR Province = 'None' THEN 1 ELSE 0 END)
FROM workspace.default.bright_tv_dataset_2
UNION ALL
SELECT 
  'Social_Media_Handle',
  COUNT(*),
  SUM(CASE WHEN `Social Media Handle` IS NULL OR `Social Media Handle` = 'None' THEN 1 ELSE 0 END)
FROM workspace.default.bright_tv_dataset_2
ORDER BY null_or_none_count DESC;


-- Check for duplicate UserIDs in viewing data
SELECT 
  UserID,
  COUNT(*) as view_count,
  COUNT(DISTINCT Channel2) as unique_channels
FROM workspace.default.bright_tv_dataset_1
GROUP BY UserID
HAVING COUNT(*) > 1
ORDER BY view_count DESC
LIMIT 100;



-- Create CLEANED combined table with proper NULL handling and SA timestamps
CREATE OR REPLACE TABLE workspace.default.bright_tv_cleaned AS
SELECT 
  A.UserID,
  CASE WHEN B.Name = 'None' THEN 'Unknown' ELSE B.Name END as Name,
  CASE WHEN B.Surname = 'None' THEN 'Unknown' ELSE B.Surname END as Surname,
  B.Email,
  CASE WHEN B.Gender = 'None' THEN 'Unknown' ELSE B.Gender END as Gender,
  CASE WHEN B.Race = 'None' THEN 'Unknown' ELSE B.Race END as Race,
  COALESCE(B.Age, 0) as Age,
  CASE WHEN B.Province = 'None' THEN 'Unknown' ELSE B.Province END as Province,
  CASE WHEN B.`Social Media Handle` = 'None' THEN 'Unknown' ELSE B.`Social Media Handle` END as Social_Media_Handle,
  A.Channel2,
  to_timestamp(A.RecordDate2, 'yyyy/MM/dd HH:mm') as RecordDate_UTC,
  from_utc_timestamp(to_timestamp(A.RecordDate2, 'yyyy/MM/dd HH:mm'), 'Africa/Johannesburg') as RecordDate_SA,
  date_format(from_utc_timestamp(to_timestamp(A.RecordDate2, 'yyyy/MM/dd HH:mm'), 'Africa/Johannesburg'), 'yyyy-MM-dd') as RecordDate_SA_Date,
  date_format(from_utc_timestamp(to_timestamp(A.RecordDate2, 'yyyy/MM/dd HH:mm'), 'Africa/Johannesburg'), 'HH:mm:ss') as RecordTime_SA,
  A.Duration_2 as Duration_UTC,
  from_utc_timestamp(A.Duration_2, 'Africa/Johannesburg') as Duration_SA,
  date_format(A.Duration_2, 'HH:mm:ss') as Duration_Formatted
FROM workspace.default.bright_tv_dataset_1 A
INNER JOIN workspace.default.bright_tv_dataset_2 B
  ON A.UserID = B.UserID;



-- Verify cleaned data: Show sample with NULL values properly handled
SELECT 
  UserID,
  Name,
  Surname,
  Gender,
  Race,
  Province,
  Channel2,
  RecordDate_SA_Date,
  RecordTime_SA,
  Duration_Formatted
FROM workspace.default.bright_tv_cleaned
WHERE Name IS NULL OR Gender IS NULL OR Race IS NULL OR Province IS NULL
LIMIT 50;


-- VIEWING PATTERN ANALYSIS: Most Watched Channels
SELECT 
  Channel2,
  COUNT(*) as total_views,
  COUNT(DISTINCT UserID) as unique_viewers,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct_of_total_views,
  ROUND(AVG(CAST(SPLIT(Duration_Formatted, ':')[0] AS INT) * 3600 + 
            CAST(SPLIT(Duration_Formatted, ':')[1] AS INT) * 60 + 
            CAST(SPLIT(Duration_Formatted, ':')[2] AS INT)), 2) as avg_duration_seconds
FROM workspace.default.bright_tv_cleaned
GROUP BY Channel2
ORDER BY total_views DESC
LIMIT 20;


-- VIEWING PATTERN ANALYSIS: Viewing by Time of Day (SA Time)
SELECT 
  CASE 
    WHEN CAST(SPLIT(RecordTime_SA, ':')[0] AS INT) BETWEEN 0 AND 5 THEN '00:00-05:59 (Late Night)'
    WHEN CAST(SPLIT(RecordTime_SA, ':')[0] AS INT) BETWEEN 6 AND 11 THEN '06:00-11:59 (Morning)'
    WHEN CAST(SPLIT(RecordTime_SA, ':')[0] AS INT) BETWEEN 12 AND 17 THEN '12:00-17:59 (Afternoon)'
    WHEN CAST(SPLIT(RecordTime_SA, ':')[0] AS INT) BETWEEN 18 AND 23 THEN '18:00-23:59 (Prime Time)'
  END as time_of_day,
  COUNT(*) as total_views,
  COUNT(DISTINCT UserID) as unique_viewers,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct_of_views
FROM workspace.default.bright_tv_cleaned
GROUP BY time_of_day
ORDER BY 
  CASE time_of_day
    WHEN '00:00-05:59 (Late Night)' THEN 1
    WHEN '06:00-11:59 (Morning)' THEN 2
    WHEN '12:00-17:59 (Afternoon)' THEN 3
    WHEN '18:00-23:59 (Prime Time)' THEN 4
  END;



-- VIEWING PATTERN ANALYSIS: Top Channels by Time of Day
WITH time_buckets AS (
  SELECT 
    CASE 
      WHEN CAST(SPLIT(RecordTime_SA, ':')[0] AS INT) BETWEEN 0 AND 5 THEN 'Late Night (00:00-05:59)'
      WHEN CAST(SPLIT(RecordTime_SA, ':')[0] AS INT) BETWEEN 6 AND 11 THEN 'Morning (06:00-11:59)'
      WHEN CAST(SPLIT(RecordTime_SA, ':')[0] AS INT) BETWEEN 12 AND 17 THEN 'Afternoon (12:00-17:59)'
      WHEN CAST(SPLIT(RecordTime_SA, ':')[0] AS INT) BETWEEN 18 AND 23 THEN 'Prime Time (18:00-23:59)'
    END as time_period,
    Channel2
  FROM workspace.default.bright_tv_cleaned
)
SELECT 
  time_period,
  Channel2,
  COUNT(*) as views,
  ROW_NUMBER() OVER (PARTITION BY time_period ORDER BY COUNT(*) DESC) as rank
FROM time_buckets
GROUP BY time_period, Channel2
QUALIFY rank <= 5
ORDER BY 
  CASE time_period
    WHEN 'Late Night (00:00-05:59)' THEN 1
    WHEN 'Morning (06:00-11:59)' THEN 2
    WHEN 'Afternoon (12:00-17:59)' THEN 3
    WHEN 'Prime Time (18:00-23:59)' THEN 4
  END,
  rank;



-- VIEWING PATTERN ANALYSIS: Demographics - Viewing by Province
SELECT 
  Province,
  COUNT(*) as total_views,
  COUNT(DISTINCT UserID) as unique_viewers,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct_of_views,
  ROUND(AVG(CAST(SPLIT(Duration_Formatted, ':')[0] AS INT) * 3600 + 
            CAST(SPLIT(Duration_Formatted, ':')[1] AS INT) * 60 + 
            CAST(SPLIT(Duration_Formatted, ':')[2] AS INT)), 2) as avg_duration_seconds
FROM workspace.default.bright_tv_cleaned
WHERE Province != 'Unknown'
GROUP BY Province
ORDER BY total_views DESC;



-- VIEWING PATTERN ANALYSIS: User Engagement Summary
SELECT 
  'Total Views' as metric,
  CAST(COUNT(*) AS STRING) as value
FROM workspace.default.bright_tv_cleaned
UNION ALL
SELECT 
  'Unique Viewers',
  CAST(COUNT(DISTINCT UserID) AS STRING)
FROM workspace.default.bright_tv_cleaned
UNION ALL
SELECT 
  'Unique Channels',
  CAST(COUNT(DISTINCT Channel2) AS STRING)
FROM workspace.default.bright_tv_cleaned
UNION ALL
SELECT 
  'Avg Views per User',
  CAST(ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT UserID), 2) AS STRING)
FROM workspace.default.bright_tv_cleaned
UNION ALL
SELECT 
  'Date Range',
  CONCAT(MIN(RecordDate_SA_Date), ' to ', MAX(RecordDate_SA_Date))
FROM workspace.default.bright_tv_cleaned;



-- ========================================
-- COMPREHENSIVE VISUALIZATION QUERY
-- ========================================
-- One denormalized table with all dimensions 

SELECT 
  UserID,
  Gender,
  Race,
  Age,
  CASE 
    WHEN Age BETWEEN 0 AND 17 THEN '00-17 (Youth)'
    WHEN Age BETWEEN 18 AND 24 THEN '18-24 (Young Adult)'
    WHEN Age BETWEEN 25 AND 34 THEN '25-34 (Adult)'
    WHEN Age BETWEEN 35 AND 44 THEN '35-44 (Middle Age)'
    WHEN Age BETWEEN 45 AND 54 THEN '45-54 (Mature)'
    WHEN Age >= 55 THEN '55+ (Senior)'
    ELSE 'Unknown'
  END as Age_Group,
  Province,
  Name,
  Surname,
  Email,
  Social_Media_Handle,
  Channel2 as Channel,
  CASE 
    WHEN Channel2 IN ('Supersport Live Events', 'ICC Cricket World Cup 2011', 'SuperSport Blitz', 'DStv Events 1', 'Wimbledon') 
      THEN 'Sports'
    WHEN Channel2 IN ('Channel O', 'Trace TV', 'MTV Base') 
      THEN 'Music'
    WHEN Channel2 IN ('Africa Magic', 'M-Net', 'Vuzu', 'kykNET', 'MK') 
      THEN 'Entertainment'
    WHEN Channel2 IN ('Cartoon Network', 'Boomerang') 
      THEN 'Kids'
    WHEN Channel2 IN ('E! Entertainment') 
      THEN 'Lifestyle'
    WHEN Channel2 IN ('CNN') 
      THEN 'News'
    WHEN Channel2 IN ('SawSee', 'Sawsee') 
      THEN 'Religious'
    ELSE 'Other'
  END as Channel_Category,
  RecordDate_SA as View_DateTime,
  RecordDate_SA_Date as View_Date,
  RecordTime_SA as View_Time,
  YEAR(RecordDate_SA) as Year,
  MONTH(RecordDate_SA) as Month,
  date_format(RecordDate_SA, 'MMMM') as Month_Name,
  DAY(RecordDate_SA) as Day,
  date_format(RecordDate_SA, 'EEEE') as Day_of_Week,
  WEEKOFYEAR(RecordDate_SA) as Week_Number,
  DAYOFWEEK(RecordDate_SA) as Day_of_Week_Number,
  HOUR(RecordDate_SA) as Hour_of_Day,
  CASE 
    WHEN HOUR(RecordDate_SA) BETWEEN 0 AND 5 THEN '1. Late Night (00-05)'
    WHEN HOUR(RecordDate_SA) BETWEEN 6 AND 11 THEN '2. Morning (06-11)'
    WHEN HOUR(RecordDate_SA) BETWEEN 12 AND 17 THEN '3. Afternoon (12-17)'
    WHEN HOUR(RecordDate_SA) BETWEEN 18 AND 23 THEN '4. Prime Time (18-23)'
  END as Time_of_Day,
  
  CASE 
    WHEN HOUR(RecordDate_SA) BETWEEN 6 AND 17 THEN 'Daytime (06-17)'
    WHEN HOUR(RecordDate_SA) BETWEEN 18 AND 23 THEN 'Evening (18-23)'
    ELSE 'Night (00-05)'
  END as Day_Part,
  Duration_Formatted,
  CAST(SPLIT(Duration_Formatted, ':')[0] AS INT) * 3600 + 
  CAST(SPLIT(Duration_Formatted, ':')[1] AS INT) * 60 + 
  CAST(SPLIT(Duration_Formatted, ':')[2] AS INT) as Duration_Seconds,
  
  ROUND((CAST(SPLIT(Duration_Formatted, ':')[0] AS INT) * 3600 + 
         CAST(SPLIT(Duration_Formatted, ':')[1] AS INT) * 60 + 
         CAST(SPLIT(Duration_Formatted, ':')[2] AS INT)) / 60.0, 2) as Duration_Minutes,
  
  CASE 
    WHEN (CAST(SPLIT(Duration_Formatted, ':')[0] AS INT) * 3600 + 
          CAST(SPLIT(Duration_Formatted, ':')[1] AS INT) * 60 + 
          CAST(SPLIT(Duration_Formatted, ':')[2] AS INT)) = 0 THEN 'No Duration'
    WHEN (CAST(SPLIT(Duration_Formatted, ':')[0] AS INT) * 3600 + 
          CAST(SPLIT(Duration_Formatted, ':')[1] AS INT) * 60 + 
          CAST(SPLIT(Duration_Formatted, ':')[2] AS INT)) < 60 THEN '< 1 min'
    WHEN (CAST(SPLIT(Duration_Formatted, ':')[0] AS INT) * 3600 + 
          CAST(SPLIT(Duration_Formatted, ':')[1] AS INT) * 60 + 
          CAST(SPLIT(Duration_Formatted, ':')[2] AS INT)) < 300 THEN '1-5 mins'
    WHEN (CAST(SPLIT(Duration_Formatted, ':')[0] AS INT) * 3600 + 
          CAST(SPLIT(Duration_Formatted, ':')[1] AS INT) * 60 + 
          CAST(SPLIT(Duration_Formatted, ':')[2] AS INT)) < 900 THEN '5-15 mins'
    WHEN (CAST(SPLIT(Duration_Formatted, ':')[0] AS INT) * 3600 + 
          CAST(SPLIT(Duration_Formatted, ':')[1] AS INT) * 60 + 
          CAST(SPLIT(Duration_Formatted, ':')[2] AS INT)) < 1800 THEN '15-30 mins'
    ELSE '30+ mins'
  END as Duration_Bucket,
  RecordDate_UTC,
  Duration_UTC,
  CASE WHEN Province = 'Unknown' THEN 1 ELSE 0 END as Has_Unknown_Province,
  CASE WHEN Gender = 'Unknown' THEN 1 ELSE 0 END as Has_Unknown_Gender,
  CASE WHEN Race = 'Unknown' THEN 1 ELSE 0 END as Has_Unknown_Race,
  CASE WHEN Age = 0 THEN 1 ELSE 0 END as Has_Unknown_Age,
   CASE 
    WHEN date_format(RecordDate_SA, 'EEEE') IN ('Saturday', 'Sunday') THEN 'Weekend'
    ELSE 'Weekday'
  END as Weekend_Flag,
  1 as View_Count
  
FROM workspace.default.bright_tv_cleaned
ORDER BY RecordDate_SA DESC;
