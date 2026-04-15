-- ========================================
-- 23. AGGREGATED DATA 
-- ========================================

SELECT
  -- Dataset 
  COUNT(*) OVER() AS Viewers_Count,
   
  -- User Identification
  COALESCE(A.UserID0, 0) AS UserID,
  COALESCE(TRIM(B.Name), 'Unknown') AS Name,
  COALESCE(TRIM(B.Surname), 'Unknown') AS Surname,
  COALESCE(TRIM(B.Email), 'Unknown') AS Email,
  
  -- Demographics
  COALESCE(TRIM(B.Gender), 'Unknown') AS Gender,
  COALESCE(TRIM(B.Race), 'Unknown') AS Race,
  COALESCE(B.Age, 0) AS Age,
  COALESCE(TRIM(B.Province), 'Unknown') AS Province,
  
  -- Age 
  CASE  
    WHEN B.Age <= 9 THEN 'Kids'
    WHEN B.Age BETWEEN 10 AND 16 THEN 'Teens'
    WHEN B.Age BETWEEN 17 AND 24 THEN 'Youth'
    WHEN B.Age BETWEEN 25 AND 35 THEN 'Adults'
    WHEN B.Age BETWEEN 36 AND 55 THEN 'Older Adults'
    WHEN B.Age BETWEEN 56 AND 75 THEN 'Seniors'
    WHEN B.Age BETWEEN 76 AND 99 THEN 'Elderly'
    ELSE 'Unknown'
  END AS Age_Group,
  
  CASE  
    WHEN B.Age <= 9 THEN '0-9'
    WHEN B.Age BETWEEN 10 AND 16 THEN '10-16'
    WHEN B.Age BETWEEN 17 AND 24 THEN '17-24'
    WHEN B.Age BETWEEN 25 AND 35 THEN '25-35'
    WHEN B.Age BETWEEN 36 AND 55 THEN '36-55'
    WHEN B.Age BETWEEN 56 AND 75 THEN '56-75'
    WHEN B.Age BETWEEN 76 AND 99 THEN '76-99'
    ELSE 'N/A'
  END AS Age_Bracket,
  
  -- Viewing Details
  COALESCE(TRIM(A.Channel2), 'Unknown') AS Channel,
  A.RecordDate2 AS Record_Date,
  DATE(CONVERT_TIMEZONE('UTC', 'Africa/Johannesburg', A.RecordDate2)) AS Viewing_Date_SA,
  
  -- Aggregated Counts
  COUNT(A.UserID0) OVER(PARTITION BY DATE(CONVERT_TIMEZONE('UTC', 'Africa/Johannesburg', A.RecordDate2))) AS Total_Viewers,
  COUNT(A.UserID0) OVER(PARTITION BY DATE(CONVERT_TIMEZONE('UTC', 'Africa/Johannesburg', A.RecordDate2)), A.Channel2) AS Unique_Viewers,
  
  -- Time Details (SA Timezone)
  CAST(DATE_FORMAT(CONVERT_TIMEZONE('UTC', 'Africa/Johannesburg', A.RecordDate2), 'HH') AS INT) AS Hour_SA,
  
  CASE 
    WHEN CAST(DATE_FORMAT(CONVERT_TIMEZONE('UTC', 'Africa/Johannesburg', A.RecordDate2), 'HH') AS INT) BETWEEN 0 AND 5 THEN 'Late Night (00-05)'
    WHEN CAST(DATE_FORMAT(CONVERT_TIMEZONE('UTC', 'Africa/Johannesburg', A.RecordDate2), 'HH') AS INT) BETWEEN 6 AND 8 THEN 'Early Morning (06-08)'
    WHEN CAST(DATE_FORMAT(CONVERT_TIMEZONE('UTC', 'Africa/Johannesburg', A.RecordDate2), 'HH') AS INT) BETWEEN 9 AND 11 THEN 'Morning (09-11)'
    WHEN CAST(DATE_FORMAT(CONVERT_TIMEZONE('UTC', 'Africa/Johannesburg', A.RecordDate2), 'HH') AS INT) BETWEEN 12 AND 14 THEN 'Afternoon (12-14)'
    WHEN CAST(DATE_FORMAT(CONVERT_TIMEZONE('UTC', 'Africa/Johannesburg', A.RecordDate2), 'HH') AS INT) BETWEEN 15 AND 17 THEN 'Late Afternoon (15-17)'
    WHEN CAST(DATE_FORMAT(CONVERT_TIMEZONE('UTC', 'Africa/Johannesburg', A.RecordDate2), 'HH') AS INT) BETWEEN 18 AND 20 THEN 'Evening (18-20)'
    WHEN CAST(DATE_FORMAT(CONVERT_TIMEZONE('UTC', 'Africa/Johannesburg', A.RecordDate2), 'HH') AS INT) BETWEEN 21 AND 23 THEN 'Night (21-23)'
    ELSE 'Unknown'
  END AS Time_Of_Day_Bucket,
  
  -- Day of Week
  DAYOFWEEK(CONVERT_TIMEZONE('UTC', 'Africa/Johannesburg', A.RecordDate2)) AS Day_Of_Week,
  
  CASE DAYOFWEEK(CONVERT_TIMEZONE('UTC', 'Africa/Johannesburg', A.RecordDate2))
    WHEN 1 THEN 'Sunday'
    WHEN 2 THEN 'Monday'
    WHEN 3 THEN 'Tuesday'
    WHEN 4 THEN 'Wednesday'
    WHEN 5 THEN 'Thursday'
    WHEN 6 THEN 'Friday'
    WHEN 7 THEN 'Saturday'
    ELSE 'Unknown'
  END AS Day_Name,
  
  CASE 
    WHEN DAYOFWEEK(CONVERT_TIMEZONE('UTC', 'Africa/Johannesburg', A.RecordDate2)) IN (1, 7) THEN 'Weekend'
    ELSE 'Weekday'
  END AS Day_Type,
  
  -- Monthly Details
  MONTH(CONVERT_TIMEZONE('UTC', 'Africa/Johannesburg', A.RecordDate2)) AS Month_Number,
  DATE_FORMAT(CONVERT_TIMEZONE('UTC', 'Africa/Johannesburg', A.RecordDate2), 'MMMM') AS Month_Name,
  YEAR(CONVERT_TIMEZONE('UTC', 'Africa/Johannesburg', A.RecordDate2)) AS Year,
  
  -- Duration Information
  COALESCE(
    CONCAT(
      LPAD(CAST(FLOOR((HOUR(A.`Duration 2`) * 3600 + MINUTE(A.`Duration 2`) * 60 + SECOND(A.`Duration 2`)) / 3600) AS STRING), 2, '0'), ':',
      LPAD(CAST(FLOOR(((HOUR(A.`Duration 2`) * 3600 + MINUTE(A.`Duration 2`) * 60 + SECOND(A.`Duration 2`)) % 3600) / 60) AS STRING), 2, '0'), ':',
      LPAD(CAST(FLOOR((HOUR(A.`Duration 2`) * 3600 + MINUTE(A.`Duration 2`) * 60 + SECOND(A.`Duration 2`)) % 60) AS STRING), 2, '0')
    ),
    '00:00:00'
  ) AS Duration_Formatted_HHMMSS,
  
  COALESCE(HOUR(A.`Duration 2`) * 3600 + MINUTE(A.`Duration 2`) * 60 + SECOND(A.`Duration 2`), 0) AS Duration_Seconds,
  
  CASE 
    WHEN HOUR(A.`Duration 2`) * 3600 + MINUTE(A.`Duration 2`) * 60 + SECOND(A.`Duration 2`) < 300 THEN 'Short (0-5 min)'
    WHEN HOUR(A.`Duration 2`) * 3600 + MINUTE(A.`Duration 2`) * 60 + SECOND(A.`Duration 2`) BETWEEN 300 AND 900 THEN 'Medium (5-15 min)'
    WHEN HOUR(A.`Duration 2`) * 3600 + MINUTE(A.`Duration 2`) * 60 + SECOND(A.`Duration 2`) BETWEEN 901 AND 1800 THEN 'Long (15-30 min)'
    WHEN HOUR(A.`Duration 2`) * 3600 + MINUTE(A.`Duration 2`) * 60 + SECOND(A.`Duration 2`) > 1800 THEN 'Very Long (30+ min)'
    ELSE 'Unknown'
  END AS Duration_Bucket,
  
  -- Weekend/Weekday Counts
  SUM(CASE WHEN DAYOFWEEK(CONVERT_TIMEZONE('UTC', 'Africa/Johannesburg', A.RecordDate2)) IN (1, 7) THEN 1 ELSE 0 END) 
    OVER(PARTITION BY A.UserID0) AS Weekend_Views,
  
  SUM(CASE WHEN DAYOFWEEK(CONVERT_TIMEZONE('UTC', 'Africa/Johannesburg', A.RecordDate2)) NOT IN (1, 7) THEN 1 ELSE 0 END) 
    OVER(PARTITION BY A.UserID0) AS Weekday_Views,
  
  -- Viewing Pattern per User
  CASE 
    WHEN SUM(CASE WHEN DAYOFWEEK(CONVERT_TIMEZONE('UTC', 'Africa/Johannesburg', A.RecordDate2)) IN (1, 7) THEN 1 ELSE 0 END) 
         OVER(PARTITION BY A.UserID0) > 
         SUM(CASE WHEN DAYOFWEEK(CONVERT_TIMEZONE('UTC', 'Africa/Johannesburg', A.RecordDate2)) NOT IN (1, 7) THEN 1 ELSE 0 END) 
         OVER(PARTITION BY A.UserID0) THEN 'Weekend Viewer'
    WHEN SUM(CASE WHEN DAYOFWEEK(CONVERT_TIMEZONE('UTC', 'Africa/Johannesburg', A.RecordDate2)) NOT IN (1, 7) THEN 1 ELSE 0 END) 
         OVER(PARTITION BY A.UserID0) > 
         SUM(CASE WHEN DAYOFWEEK(CONVERT_TIMEZONE('UTC', 'Africa/Johannesburg', A.RecordDate2)) IN (1, 7) THEN 1 ELSE 0 END) 
         OVER(PARTITION BY A.UserID0) THEN 'Weekday Viewer'
    ELSE 'Balanced Viewer'
  END AS Viewing_Pattern
  
FROM workspace.default.bright_tv_v A
LEFT JOIN workspace.default.bright_tv_u B
  ON A.UserID0 = B.UserID
ORDER BY A.RecordDate2 DESC, A.UserID0;
