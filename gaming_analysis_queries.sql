/***********************************************************
PART 1: MARKET OVERVIEW (Android vs iOS)
***********************************************************/

-- Let's start with a basic split: How many apps are we looking at per platform?
SELECT 
    Platform, 
    AVG(Rating) AS Average_Rating, 
    COUNT(*) AS Total_Apps
FROM all_apps_analysis
GROUP BY Platform;

-- Checking the "Revenue Model": Do people actually pay for apps?
-- This query shows a huge gap between Android (mostly free) and iOS (lots of paid apps).
SELECT 
    Platform,
    CASE WHEN Price = 0 THEN 'Free' ELSE 'Paid' END AS Revenue_Model,
    COUNT(DISTINCT App) AS Unique_Apps,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(PARTITION BY Platform) as Percentage
FROM all_apps_analysis
GROUP BY Platform, Revenue_Model;

-- Cleaning up messy categories: Unifying 'Game' and 'Games', 'Social' and 'Social Networking', etc.
-- This was a crucial step to get accurate counts.
WITH CleanedData AS (
    SELECT 
        Platform, App, rating, reviews,
        CASE 
            WHEN Category IN ('GAME', 'GAMES') THEN 'GAMES'
            WHEN Category IN ('BOOK', 'BOOKS_AND_REFERENCE') THEN 'BOOKS'
            WHEN Category IN ('FOOD & DRINK', 'FOOD_AND_DRINK') THEN 'FOOD & DRINK'
            WHEN Category IN ('HEALTH & FITNESS', 'HEALTH_AND_FITNESS') THEN 'HEALTH & FITNESS'
            WHEN Category IN ('SOCIAL', 'SOCIAL NETWORKING') THEN 'SOCIAL'
            ELSE Category 
        END AS Clean_Category
    FROM all_apps_analysis
)
SELECT Platform, Clean_Category, COUNT(DISTINCT App) as Total_Apps
FROM CleanedData
GROUP BY 1, 2
ORDER BY 3 DESC;


/***********************************************************
PART 2: IN-GAME PURCHASE ANALYSIS (The Deep Dive)
***********************************************************/

-- Looking at the money: Who are our Top 5 spenders by country in 2025?
SELECT country, SUM(InAppPurchaseAmount) AS total_country_revenue
FROM mobile_game_in_app_purchases
WHERE lastpurchasedate LIKE '2025%'
GROUP BY country
ORDER BY total_country_revenue DESC
LIMIT 5;

-- Checking seasonality: Does revenue grow as we get closer to summer?
-- Observation: April peaked, but August was surprisingly low. Let's see why.
SELECT 
    MONTHNAME(lastpurchasedate) AS Month_Name, 
    SUM(InAppPurchaseAmount) AS Revenue,
    COUNT(*) AS Transaction_Count,
    ROUND(AVG(InAppPurchaseAmount), 2) AS Avg_Ticket_Size
FROM mobile_game_in_app_purchases
WHERE MONTH(lastpurchasedate) IN (4, 8)
GROUP BY Month_Name, MONTH(lastpurchasedate)
ORDER BY MONTH(lastpurchasedate);


/***********************************************************
PART 3: THE "WHALE" INVESTIGATION (India & Fighting Genre)
***********************************************************/

-- April looked great, but was it mass popularity or just a few big spenders?
-- Here I'm checking if India's revenue comes from 1,000 people or just 1.
SELECT 
    Country, 
    Device, 
    COUNT(DISTINCT userid) AS unique_players, 
    SUM(InAppPurchaseAmount) AS Total_Revenue,
    COUNT(*) AS total_transactions,
    ROUND(AVG(InAppPurchaseAmount), 2) AS Avg_Per_Check
FROM mobile_game_in_app_purchases
WHERE MONTH(lastpurchasedate) = 4 AND gamegenre = 'Fighting'
GROUP BY Country, Device
ORDER BY Total_Revenue DESC;
-- Result: In India, the genre was carried by only 3 people! 
-- They made about 2 big purchases each, around $3k per check. 


/***********************************************************
PART 4: FINDING THE REAL WINNER
***********************************************************/

-- Since Fighting was "inflated" by whales, let's find the real long-term winner.
-- Battle Royale has more consistent revenue and a healthier player distribution.
SELECT 
    COUNT(DISTINCT userid) as different_users, 
    GameGenre,  
    SUM(InAppPurchaseAmount) AS Total_Revenue
FROM mobile_game_in_app_purchases
GROUP BY GameGenre
ORDER BY Total_Revenue DESC;


/***********************************************************
PART 5: USER DEMOGRAPHICS & PAYMENTS
***********************************************************/

-- Who is our core audience? (Average age and spending by gender)
SELECT gender, ROUND(AVG(age), 0) AS avg_user_age, COUNT(*) AS total_purchases
FROM mobile_game_in_app_purchases
GROUP BY gender;

-- How do they like to pay?
SELECT PaymentMethod, COUNT(*) AS usage_count, ROUND(AVG(age), 0) AS avg_age
FROM mobile_game_in_app_purchases
GROUP BY PaymentMethod
ORDER BY usage_count DESC;
