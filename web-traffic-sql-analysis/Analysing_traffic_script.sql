-- =========================================================================================================================================
-- Which UTM content performed best in terms of conversion rate, and 
-- what insights can be drawn from the performance of g_ad, b_ad_2, and the null group?

SELECT ws.utm_content,
	   COUNT(DISTINCT ws.website_session_id) AS sessions,
       COUNT(DISTINCT o.order_id) AS orders,
       COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id) * 100 AS session_to_order_conv_rt
FROM 
	website_sessions as ws
LEFT JOIN 
	orders  as o 
ON 
	ws.website_session_id = o.website_session_id
GROUP BY 1
ORDER BY 2 DESC; 
/*
	Based on the data, g_ad campaigns perform well overall, especially g_ad_2 with a strong conversion rate of 7.53%. 
	Interestingly, b_ad_2 has the highest conversion rate at 8.86%, despite lower traffic, 
	indicating high efficiency. The null group, which lacks utm_content tracking, also shows solid performance. 
	These insights suggest that both g_ad and b_ad_2 content are effective and worth further analysis
*/
-- ============================================================================================================================================

-- Which combinations of UTM source, campaign, and referring website generated the highest number of website sessions?

 SELECT 
		utm_source,
        utm_campaign,
        http_referer,
        COUNT(DISTINCT website_session_id) as Sessions
FROM website_sessions
GROUP BY 1,2,3 
ORDER BY sessions DESC; 

/* 
	The majority of website sessions are driven by the gsearch and bsearch sources under the nonbrand campaign, 
	with gsearch leading significantly at 282,706 sessions. 
	This indicates that generic (nonbranded) search campaigns are the primary drivers of traffic. 
	In contrast, brand campaigns and social sources like socialbook contribute smaller volumes, 
	suggesting that the nonbrand search strategy is currently the most effective at attracting users.
*/
-- ========================================================================================================================================

-- How do conversion rates differ between desktop and mobile users on our e-commerce platform, 
-- and what might this data suggest about our mobile user experience?

SELECT 
	ws.device_type AS device_type,
    COUNT(DISTINCT ws.website_session_id) as sessions, 
    COUNT(DISTINCT o.order_id) AS orders, 
    COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id) as conversion_rate 
FROM website_sessions ws 
LEFT JOIN  orders o 
ON ws.website_session_id = o.website_session_id
GROUP BY 1; 

/* Analysis reveals a significant conversion gap between devices. 
Desktop users convert at 8.50% compared to just 3.09% for mobile users - a nearly 3x */

