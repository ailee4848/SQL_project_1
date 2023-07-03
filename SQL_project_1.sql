/*Analyzing Traffic sources
1.Help to understand where the bulk of the website session are coming from,like to see the breakdown
by UTM source,campaign and referring domain if possible */
use mavenfuzzyfactory;
select utm_source, utm_campaign, http_referer,
count(distinct website_session_id) as sessions
from website_sessions
where created_at < '2012-04-12'
group by 1,2,3
order by 4 desc;

/* 2. Calculate the CVR from session to order.We need CVR at least 4% to make the numbers work */
Select count(distinct website_sessions.website_session_id) as sessions,
       count(distinct orders.order_id) as orders,
       count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as session_to_order_cvr
from website_sessions 
left join orders 
on website_sessions.website_session_id = orders.website_session_id
where website_sessions.created_at < '2012-04-14' and utm_source = 'gsearch' and utm_campaign = 'nonbrand'

/*3.BID optimization and Trend analysis
Pull 'gsearch' and 'nonbrand' trended session volume,by week to see if the bid changes have caused volume to drop at all */
select min(date(created_at)) as week_start_date,
count(distinct website_session_id) as sessions
from website_sessions
where created_at < '2012-05-12' and utm_source ='gsearch' and utm_content ='nonbrand'
group by year(created_at), week(created_at)

/*4. Device-level perfomance.
Pull conversation rates from session to order by device type?If desktop perfomance is better
than on mobile way we may be able to bid up for deskstop to get more volume */
select website_sessions.device_type,count(distinct website_sessions.website_session_id) as sessions,
count(distinct orders.order_id) as orders,
count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as session_to_order_cvr
from website_sessions left join orders on
website_sessions.website_session_id = orders.website_session_id
where website_sessions.created_at < '2012-05-12' and utm_source ='gsearch' and utm_content ='nonbrand'
group by 1
/* 5. Gsearch device-level perfomance
Pull weekly trends for both dekstop and mobile so we can see the impact on volume */
select min(date(created_at)) as week_start_date,
count(distinct case when device_type ='desctop' then website_session_id else null end) as dtop_session,
count(distinct case when device_type = 'mobile' then website_session_id else null end) as mob_session
from website_sessions
where created_at < '2012-06-09' and created_at > '2012-04-15'
and utm_source ='gsearch' and utm_content ='nonbrand'
group by year(created_at),week(created_at)

/* Analyzing WEBSITE perfomance
1.Pull the most-viewed website pages,ranked by session volume */
select pageview_url,count(distinct website_pageview_id) as pvs
from website_pageviews
where created_at <'2012-06-09'
group by 1
order by 2 desc
/* 2.Pull a list of the top entry pages and rank them on entry volume.*/
create temporary table first_pages
select 
website_session_id,min(website_pageview_id) as first_pageview
from website_pageviews
where created_at <'2012-06-12'
group by 1
order by 2

select website_pageviews.pageview_url as landing,
count(distinct first_pages.website_session_id) as session_hitting_page
from first_pages left join website_pageviews on
first_pages.first_pageview=website_pageviews.website_pageview_id
group by 1

/*3.Analyzing bounce rates and landing page tests
Calculating baunced rated*/
select  website_session_id,min(website_pageview_id) as min_pageview_id
from website_pageviews
where created_at < '2012-06-14'
group by 1

create temporary table first_pageview
select  website_session_id,min(website_pageview_id) as min_pageview_id
from website_pageviews
where created_at < '2012-06-14'
group by 1
 
 Create temporary table session_w_landing_page
 select first_pageview.website_session_id,website_pageviews.pageview_url as landing_page
 from first_pageview left join website_pageviews
 on website_pageviews.website_pageview_id = first_pageview.min_pageview_id
 where website_pageviews.pageview_url = '/home'
 
create temporary table bounced_session
select session_w_landing_page.website_session_id,session_w_landing_page.landing_page,
count(website_pageviews.website_pageview_id) as count_of_pages_viewed
from session_w_landing_page left join website_pageviews 
 on website_pageviews.website_pageview_id = session_w_landing_page.website_session_id
 group by 1,2
 having 3 = 1;
 
 select session_w_landing_page.website_session_id, bounced_session.website_session_id as bounced_session
 from session_w_landing_page left join bounced_session
 on session_w_landing_page.website_session_id= bounced_session.website_session_id
 order by 1;
  select count(distinct session_w_landing_page.website_session_id) as total_session,
  count(distinct bounced_session.website_session_id) as bounced_session,
  count(distinct bounced_session.website_session_id)/count(distinct session_w_landing_page.website_session_id) as bounce_rate
  from session_w_landing_page left join bounced_session
 on session_w_landing_page.website_session_id= bounced_session.website_session_id;
 
 /* Pull bounce rates for the two groups so we can eveluute two pages.
 -Step 0: Find out when the new page "/lander-1" was launche */
 select min(date (created_at)) as first_created_at,min(website_pageview_id) as first_pageview_id
 from website_pageviews
where   pageview_url = '/lander-1' and created_at is not null
/* Step 1: finding the first website_pageview_id for relevant session*/
Create temporary table 1_test_pageview
select website_pageviews.website_session_id,min(distinct website_pageviews.website_pageview_id) as min_pageview_id
from website_pageviews inner join website_sessions 
on website_sessions.website_session_id = website_pageviews.website_session_id
and website_pageviews.created_at <'2012-07-28' and website_pageviews.website_pageview_id = 23504 
and website_sessions.utm_source ='gsearch' and website_sessions.utm_content ='nonbrand'
group by 1;

/* Step 2.Identifying the landing page for each session.*/

Create temporary table nonbrand_test_landing_page_for_session
 select 1_test_pageview.website_session_id,website_pageviews.pageview_url as landing_page
 from 1_test_pageview left join website_pageviews
 on website_pageviews.website_pageview_id = 1_test_pageview.min_pageview_id
 where website_pageviews.pageview_url in ('/home' ,'lander-1')
 
 /* Step 3:counting pageviews for each sessions,to identify bounces*/
 create temporary table nonbrand_test_w_bounced_session
 select nonbrand_test_landing_page_for_session.website_session_id,
 nonbrand_test_landing_page_for_session.landing_page,
 count( website_pageviews.website_pageview_id) as count_of_page_viewed
 from nonbrand_test_landing_page_for_session left join website_pageviews
 on website_pageviews.website_session_id = nonbrand_test_landing_page_for_session.website_session_id
 group by 1,2
 having count( website_pageviews.website_pageview_id) = 1 ;
 
 select nonbrand_test_landing_page_for_session.landing_page,
 count(distinct nonbrand_test_landing_page_for_session.website_session_id) as sessions,
 count(distinct nonbrand_test_w_bounced_session.website_session_id) as bounced_sessions,
 count(distinct nonbrand_test_w_bounced_session.website_session_id)/count(distinct nonbrand_test_landing_page_for_session.website_session_id) 
 as bounce_rates
 from nonbrand_test_w_bounced_session left join nonbrand_test_landing_page_for_session
 on nonbrand_test_landing_page_for_session.website_session_id = nonbrand_test_w_bounced_session.website_session_id
group by 1 ;

/* Landing page trend analysis:Pull overall paid search bounce rate trended weekly
Step 1: finding the first website_pageview_id for relevant session */
 create temporary table session_with_m_view_count
 select website_sessions.website_session_id,
 min(website_pageviews.website_pageview_id) as first_pageview_id,
 count(website_pageviews.website_pageview_id) as count_pageview_id
 from website_pageviews left join website_sessions
 on website_sessions.website_session_id = website_pageviews.website_session_id
 where website_sessions.created_at >'2012-06-01' and website_sessions.created_at <'2012-08-30'
and website_sessions.utm_source ='gsearch' and website_sessions.utm_content ='nonbrand'
group by 1;
select * from session_with_m_view_count

create temporary table sessions_w_counts_lander_and_created_at
select session_with_m_view_count.website_session_id,
session_with_m_view_count.first_pageview_id,
session_with_m_view_count.count_pageviews,
website_pageviews.pageview_url as landing_page,
website_pageviews.created_at as session_created_at
 from session_with_m_view_count left join website_pageviews
 on session_with_m_view_count.website_session_id=website_pageviews.website_session_id
 /*Step 4: summarazing by week */
 select 
 min(date(session_created_at)) as week_start_date,
 count(distinct case when count_pageviews = 1 then website_session_id else null end) as bounced_sessions,
 count(distinct case when count_pageviews =1 then website_session_id else null end )as *1.0 /count(distinct website_session-id) as bounce_rate,
 count(distinct case when landing_page = '/home' then website_session_id else null end) as home_session,
count(distinct case when landing_page = 'lander-1' then website_session_id else null end) as lander_session
 from sessions_w_counts_lander_and_created_at
 group by 1
 






