/* Q1: Which website pages are the most common entry (landing) points for users, 
and what does this indicate about user behavior or traffic sources? */


WITH first_pageview AS
(
SELECT
	website_session_id,
	MIN(website_pageview_id) AS min_pv_id
FROM website_pageviews
GROUP BY website_session_id
)
SELECT
	wp.pageview_url AS landing_page, -- AKA "entry page"
    COUNT(DISTINCT fp.website_session_id) AS sessions_hitting_this_lander
FROM first_pageview AS fp
LEFT JOIN website_pageviews AS wp
ON fp.min_pv_id = wp.website_pageview_id
GROUP BY 1;

/*The /home page is the most common entry point with 137,576 sessions, 
indicating that many users either navigate directly to the site or land via branded search or bookmarks.
Understanding which pages users enter the site through helps identify successful traffic sources and landing page performance. 
Pages with high entry counts are likely tied to effective. */

-- ==============================================================================================================================


/*
Analyze user sessions that land on the homepage (/home) and calculate the bounce rate. 
A bounce is defined as a session where the user viewed only a single page. What is the bounce rate for homepage visitors, 
and what might this suggest about the performance of the homepage as an entry point??*/

-- Question 2: 

-- STEP 1: Identify the first pageview for each user session
CREATE TEMPORARY TABLE first_pageviews AS
SELECT  
    website_session_id, 
    MIN(website_pageview_id) AS min_pageview_id
FROM website_pageviews
GROUP BY website_session_id;

-- STEP 2: Filter sessions that landed on the homepage (/home)
CREATE TEMPORARY TABLE sessions_w_home_land_page AS
SELECT 
    fp.website_session_id, 
    wp.pageview_url AS landing_page 
FROM first_pageviews AS fp
LEFT JOIN website_pageviews AS wp
    ON fp.min_pageview_id = wp.website_pageview_id 
WHERE wp.pageview_url = '/home';

-- STEP 3: Identify bounced sessions (only one pageview)
CREATE TEMPORARY TABLE bounced_sessions AS
SELECT 
    s.website_session_id,
    s.landing_page,
    COUNT(wp.website_pageview_id) AS count_of_pages_viewed
FROM sessions_w_home_land_page AS s
LEFT JOIN website_pageviews AS wp
    ON wp.website_session_id = s.website_session_id
GROUP BY 1, 2
HAVING COUNT(wp.website_pageview_id) = 1;

-- STEP 4: Calculate total sessions, bounced sessions, and bounce rate
SELECT 
    COUNT(DISTINCT s.website_session_id) AS total_sessions,
    COUNT(DISTINCT b.website_session_id) AS bounced_sessions,
    COUNT(DISTINCT b.website_session_id) * 100.0 / COUNT(DISTINCT s.website_session_id) AS bounced_rate 
FROM sessions_w_home_land_page AS s
LEFT JOIN bounced_sessions AS b
    ON s.website_session_id = b.website_session_id;
    
-- '{Total sessions that landed on /home: 137,576}, {Bounced sessions (only 1 pageview): 57,346}, {Bounce rate: 41.68%}'
-- Out of 137,576 sessions that started on the homepage, 41.68% bounced, meaning users exited the site after viewing only that first page.
-- This bounce rate is moderately high and indicates that a significant portion of users are not finding a compelling reason to continue navigating beyond the homepage.

-- ==============================================================================================================================

-- 		QUESTION 3 

/* Using SQL, analyze and compare the user conversion funnels for /lander-1 and /lander-2. 
Evaluate how users progress through each stage of the e-commerce journey—from landing to product view, product detail, cart, shipping, and billing. 
What does the data suggest about user behavior across these landers? 
In particular, identify reasons behind the sharp drop-off between the shipping and billing stages and recommend actions to optimize the funnel.
 */

CREATE TEMPORARY TABLE session_level_made_it_flag_lander1
SELECT website_session_id, 
		MAX(product_page) AS product_made_it,
		MAX(mr_fuzzy_page) AS mr_fuzzy_page,
        MAX(cart_page) AS cart_page,
        MAX(shipping_page) AS shipping_page,
        MAX(billing_page) AS billing_page
FROM (
SELECT 
		website_sessions.website_session_id,
        website_pageviews.pageview_url ,
        website_pageviews.created_at,
        CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS product_page,
        CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mr_fuzzy_page,
        CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
        CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
        CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
        CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thanku_page
FROM website_sessions
LEFT JOIN website_pageviews
ON website_sessions.website_session_id = website_pageviews.website_session_id 
WHERE  website_pageviews.pageview_url IN ('/lander-1','/products','/the-original-mr-fuzzy','/cart','/shipping','/billing','/thank-you-for-your-order')
GROUP BY 1,2,3) AS pageview_level 
GROUP BY 1;

SELECT 
		COUNT(DISTINCT website_session_id) AS sessions,
		COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT website_session_id) * 100 AS to_products,
        COUNT(DISTINCT CASE WHEN mr_fuzzy_page = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) * 100 AS to_mr_fuzzy_page,
        COUNT(DISTINCT CASE WHEN cart_page = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN mr_fuzzy_page = 1 THEN website_session_id ELSE NULL END) * 100 AS to_cart_page,
        COUNT(DISTINCT CASE WHEN shipping_page = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN cart_page = 1 THEN website_session_id ELSE NULL END) * 100 AS to_shipping_page,
        COUNT(DISTINCT CASE WHEN billing_page = 1 THEN website_session_id ELSE NULL END)/ COUNT(DISTINCT CASE WHEN shipping_page = 1 THEN website_session_id ELSE NULL END) * 100 AS to_billing_page
FROM session_level_made_it_flag_lander1;

-- ---------------------
-- Conversion Funnel for Lander 2 

CREATE TEMPORARY TABLE session_level_made_it_flag_lander2
SELECT website_session_id, 
		MAX(product_page) AS product_made_it,
		MAX(mr_fuzzy_page) AS mr_fuzzy_page,
        MAX(cart_page) AS cart_page,
        MAX(shipping_page) AS shipping_page,
        MAX(billing_page) AS billing_page
FROM (
SELECT 
		website_sessions.website_session_id,
        website_pageviews.pageview_url ,
        website_pageviews.created_at,
        CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS product_page,
        CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mr_fuzzy_page,
        CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
        CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
        CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
        CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thanku_page
FROM website_sessions
LEFT JOIN website_pageviews
ON website_sessions.website_session_id = website_pageviews.website_session_id 
WHERE  website_pageviews.pageview_url IN ('/lander-2','/products','/the-original-mr-fuzzy','/cart','/shipping','/billing','/thank-you-for-your-order')
GROUP BY 1,2,3) AS pageview_level 
GROUP BY 1;

SELECT 
		COUNT(DISTINCT website_session_id) AS sessions,
		COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT website_session_id) * 100 AS to_products,
        COUNT(DISTINCT CASE WHEN mr_fuzzy_page = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) * 100 AS to_mr_fuzzy_page,
        COUNT(DISTINCT CASE WHEN cart_page = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN mr_fuzzy_page = 1 THEN website_session_id ELSE NULL END) * 100 AS to_cart_page,
        COUNT(DISTINCT CASE WHEN shipping_page = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN cart_page = 1 THEN website_session_id ELSE NULL END) * 100 AS to_shipping_page,
        COUNT(DISTINCT CASE WHEN billing_page = 1 THEN website_session_id ELSE NULL END)/ COUNT(DISTINCT CASE WHEN shipping_page = 1 THEN website_session_id ELSE NULL END) * 100 AS to_billing_page
FROM session_level_made_it_flag_lander2;

/* 
 = lander-1 had a stronger start with 91.16% of users viewing the product page, compared to 81.51% from /lander-2, indicating higher initial engagement.
 = Beyond the product page, both landers followed an identical path of conversion through to cart and shipping stages.
 = A significant drop-off is observed between the shipping and billing pages, where conversion falls to just 5.61% for both landers.
 = It's also possible that users proceed directly to a confirmation or thank-you page, bypassing a distinct billing page. 
 */
