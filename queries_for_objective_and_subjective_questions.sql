-- SOCIAL MEDIA ANALYSIS USING MYSQL


-- Problem Statement
-- You are hired as a data analyst at Meta and asked to collaborate with Marketing team.
-- Marketing teams wants to leverage Instagram's user data to develop targeted marketing 
-- strategies that will increase user engagement, retention, and acquisition. Provide 
-- insights and recommendations to address the following objectives



-- ANSWERS TO OBJECTIVE AND SUBJECTIVE QUESTIONS


-- Objective Question 1
-- Are there any tables with duplicate or missing null values? If so, how would you handle them?

-- CHECKING DUPLICATES FOR USERS TABLE

SELECT id, username, created_at FROM users
GROUP BY id, username, created_at
HAVING COUNT(*) > 1
;

-- CHECKING DUPLICATES FOR PHOTOS TABLE

SELECT id, image_url, user_id, created_dat FROM photos
GROUP BY id, image_url, user_id, created_dat
HAVING COUNT(*) > 1
;

-- CHECKING DUPLICATES FOR COMMENTS TABLE

SELECT id, comment_text, user_id, photo_id, created_at FROM comments
GROUP BY id, comment_text, user_id, photo_id, created_at
HAVING COUNT(*) > 1
;

-- CHECKING DUPLICATES FOR LIKES TABLE

SELECT id, user_id, photo_id, created_at FROM likes
GROUP BY id, user_id, photo_id, created_at
HAVING COUNT(*) > 1
;

-- CHECKING DUPLICATES FOR FOLLOWS TABLE

SELECT follower_id, followee_id, created_at FROM follows
GROUP BY follower_id, followee_id, created_at
HAVING COUNT(*) > 1
;

-- CHECKING DUPLICATES FOR TAGS TABLE

SELECT id, tag_name, created_at FROM tags
GROUP BY id, tag_name, created_at
HAVING COUNT(*) > 1
;

-- CHECKING DUPLICATES FOR PHOTO_TAGS TABLE

SELECT photo_id, tag_id FROM photo_tags
GROUP BY photo_id, tag_id
HAVING COUNT(*) > 1
;



-- Objective Question 2
-- What is the distribution of user activity levels (e.g., number of posts, likes, comments) 
-- across the user base?

WITH photo_cnt AS(
	SELECT u.id user_id, u.username,
		COUNT(p.id) number_of_posts
FROM users u 
	LEFT JOIN photos p ON u.id=p.user_id    
GROUP BY u.id
),
comment_cnt AS(
	SELECT u.id user_id,
    COUNT(c.id) number_of_comments
FROM users u 
    LEFT JOIN comments c ON u.id=c.user_id
GROUP BY u.id
),
like_cnt AS(
	SELECT u.id user_id,
    COUNT(l.user_id) number_of_likes
FROM users u 
    LEFT JOIN likes l ON u.id=l.user_id
GROUP BY u.id
)
SELECT a.user_id, a.username,a.number_of_posts,b.number_of_comments,c.number_of_likes
FROM photo_cnt a JOIN comment_cnt b ON a.user_id=b.user_id
	JOIN like_cnt c ON a.user_id=c.user_id;


-- Objective Question 3
-- Calculate the average number of tags per post (photo_tags and photos tables).

WITH photo_tag_count AS(
	SELECT p.id, COUNT(tag_id) tag_count
	FROM photos p LEFT JOIN photo_tags pt ON p.id=pt.photo_id
	GROUP BY p.id
)
SELECT AVG(tag_count) AS average_number_of_tags_per_post FROM photo_tag_count;



-- Objective Question 4
-- Identify the top users with the highest engagement rates (likes, comments) 
-- on their posts and rank them.

WITH user_post_likes AS(
	SELECT p.user_id,
		COUNT(l.photo_id) like_cnt
    FROM photos p JOIN likes l ON p.id=l.photo_id
    GROUP BY p.user_id
),
user_post_comments AS(
	SELECT p.user_id,
		COUNT(c.id) comment_cnt
    FROM photos p JOIN comments c ON p.id=c.photo_id
    GROUP BY p.user_id
)
SELECT a.id user_id,
a.username,
COALESCE(b.like_cnt,0) number_of_likes,
COALESCE(c.comment_cnt,0) number_of_comments,
COALESCE(b.like_cnt,0) + COALESCE(c.comment_cnt,0) total_engagement,
DENSE_RANK() OVER(ORDER BY (COALESCE(b.like_cnt,0) + COALESCE(c.comment_cnt,0)) DESC) engagement_ranking
FROM users a LEFT JOIN user_post_likes b ON a.id=b.user_id
LEFT JOIN user_post_comments c ON a.id=c.user_id;


-- Objective Question 5
-- Which users have the highest number of followers and followings?

-- FOR HIGHEST NUMBER OF FOLLOWERS

WITH user_followers AS(
	SELECT followee_id,
		COUNT(follower_id) AS number_of_followers
    FROM follows
    GROUP BY followee_id
)
SELECT u.id user_id, u.username, uf.number_of_followers
FROM users u JOIN user_followers uf ON u.id=uf.followee_id
WHERE uf.number_of_followers = (SELECT MAX(number_of_followers) FROM user_followers);


-- FOR HIGHEST NUMBER OF FOLLOWINGS

WITH user_followings AS(
	SELECT follower_id,
		COUNT(followee_id) AS number_of_followings
    FROM follows
    GROUP BY follower_id
)
SELECT u.id user_id, u.username, uf.number_of_followings
FROM users u JOIN user_followings uf ON u.id=uf.follower_id
WHERE uf.number_of_followings = (SELECT MAX(number_of_followings) FROM user_followings);


-- Objective Question 6
-- Calculate the average engagement rate (likes, comments) per post for each user.

WITH photo_engagement AS (
    SELECT
        p.user_id,
        p.id AS photo_id,
        COUNT(DISTINCT l.user_id) AS like_count,
        COUNT(DISTINCT c.id) AS comment_count,
        COUNT(DISTINCT l.user_id) + COUNT(DISTINCT c.id) AS total_engagement
    FROM
        photos p
        LEFT JOIN likes l ON p.id = l.photo_id
        LEFT JOIN comments c ON p.id = c.photo_id
    GROUP BY
        p.id
)
SELECT u.id user_id,
	ROUND(AVG(COALESCE(like_count,0)),2) avg_likes_per_photo,
    ROUND(AVG(COALESCE(comment_count,0)),2) avg_comments_per_photo,
    ROUND(AVG(COALESCE(total_engagement,0)),2) avg_engagement_per_photo
FROM users u LEFT JOIN photo_engagement pe ON u.id=pe.user_id
GROUP BY u.id
ORDER BY avg_engagement_per_photo DESC;


-- Objective Question 7
-- Get the list of users who have never liked any post (users and likes tables)

SELECT u.id user_id, u.username
FROM users u LEFT JOIN likes l ON u.id=l.user_id
WHERE l.user_id IS NULL;


-- Objective Question 10
-- Calculate the total number of likes, comments, and photo tags for each user.


 WITH total_comments AS(
	SELECT user_id, count(c.id) AS number_of_comments 
	FROM users u JOIN comments c ON u.id=c.user_id
    GROUP BY u.id),
total_likes AS(
	SELECT user_id,COUNT(l.user_id) AS number_of_likes 
	FROM users u JOIN likes l ON u.id=l.user_id
    GROUP BY u.id),
total_photo_tags AS(
	SELECT user_id,count(pt.tag_id) AS number_of_photo_tags
    FROM users u JOIN photos p ON u.id=p.user_id
		JOIN photo_tags pt ON p.id=pt.photo_id
    GROUP BY u.id)
SELECT u.id user_id,
	username,
	COALESCE(tl.number_of_likes,0) total_likes,
	COALESCE(tc.number_of_comments,0) total_comments,
    COALESCE(tpt.number_of_photo_tags,0) total_photo_tags
FROM users u LEFT JOIN total_comments tc ON u.id=tc.user_id
	LEFT JOIN total_likes tl ON u.id=tl.user_id 
    LEFT JOIN total_photo_tags tpt ON u.id=tpt.user_id;


-- Objective Question 11
-- Rank users based on their total engagement (likes, comments, shares) over a month.

WITH user_engagement AS (
    SELECT
        p.user_id,
        COUNT(DISTINCT l.user_id) AS number_of_likes,
        COUNT(DISTINCT c.id) AS number_of_comments,
        COUNT(DISTINCT l.user_id) + COUNT(DISTINCT c.id) AS total_engagement
    FROM
        photos p
        LEFT JOIN likes l ON p.id = l.photo_id
        LEFT JOIN comments c ON p.id = c.photo_id
    WHERE
        p.created_dat >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
    GROUP BY
        p.user_id
)
SELECT
    ue.user_id,
    u.username,
    ue.total_engagement,
    RANK() OVER (ORDER BY ue.total_engagement DESC) AS engagement_ranking
FROM
    user_engagement ue
    JOIN users u ON ue.user_id = u.id
ORDER BY
    engagement_ranking;



-- Objective Question 12
-- Retrieve the hashtags that have been used in posts with the highest average number of likes.
-- Use a CTE to calculate the average likes for each hashtag first.


WITH likes_per_tag AS( 
	SELECT pt.tag_id,p.id, 
		COUNT(l.user_id) as number_of_likes 
    FROM photo_tags pt JOIN photos p ON pt.photo_id = p.id 
		JOIN likes l ON p.id = l.photo_id 
    GROUP BY pt.tag_id,p.id
)
SELECT t.tag_name,
	ROUND(AVG(a.number_of_likes),2) avg_number_of_likes  
FROM likes_per_tag a JOIN tags t ON a.tag_id = t.id 
GROUP BY a.tag_id
ORDER BY AVG(a.number_of_likes) DESC;


-- Objective Question 13
-- Retrieve the users who have started following someone after being followed by that person

SELECT u.id user_id,
	username
FROM users u JOIN follows f1 ON u.id=f1.follower_id
	JOIN follows f2 ON u.id=f2.followee_id AND f1.followee_id=f2.follower_id
WHERE f1.created_at>f2.created_at;



-- Subjective Question 1
-- Based on user engagement and activity levels, which users would you consider the most loyal 
-- or valuable? How would you reward or incentivize these users?

WITH content_liked_by_user AS (
    SELECT user_id, COUNT(*) AS like_cnt
    FROM likes
    GROUP BY user_id
),
comments_from_user AS (
    SELECT user_id, COUNT(*) AS comment_cnt
    FROM comments
    GROUP BY user_id
),
photos_uploaded_by_user AS (
    SELECT user_id, COUNT(*) AS photos_uploaded_cnt
    FROM photos
    GROUP BY user_id
),
likes_received AS (
    SELECT p.user_id, COUNT(*) AS likes_received_cnt
    FROM likes l
    JOIN photos p ON l.photo_id = p.id
    GROUP BY p.user_id
),
comments_received AS (
    SELECT p.user_id, COUNT(*) AS comments_received_cnt
    FROM comments c
    JOIN photos p ON c.photo_id = p.id
    GROUP BY p.user_id
),
followers AS (
    SELECT followee_id AS user_id, COUNT(*) AS followers_cnt
    FROM follows
    GROUP BY followee_id
),
followings AS (
    SELECT follower_id AS user_id, COUNT(*) AS following_cnt
    FROM follows
    GROUP BY follower_id
),
overall_engagement AS (
    SELECT u.id AS user_id, u.username,
        COALESCE(lk.like_cnt, 0) +
        COALESCE(cm.comment_cnt, 0) + 
        COALESCE(p.photos_uploaded_cnt, 0) +
        COALESCE(lr.likes_received_cnt, 0) +
        COALESCE(cr.comments_received_cnt, 0) +
		COALESCE(f1.followers_cnt, 0) + COALESCE(f2.following_cnt, 0) 
        AS total_engagement
    FROM 
        users u
    LEFT JOIN content_liked_by_user lk ON u.id = lk.user_id
    LEFT JOIN comments_from_user cm ON u.id = cm.user_id
    LEFT JOIN photos_uploaded_by_user p ON u.id = p.user_id
    LEFT JOIN likes_received lr ON u.id = lr.user_id
    LEFT JOIN comments_received cr ON u.id = cr.user_id
    LEFT JOIN followers f1 ON u.id = f1.user_id
    LEFT JOIN followings f2 ON u.id = f2.user_id
)
SELECT 
    user_id,
    username,
    total_engagement,
    RANK() OVER (ORDER BY total_engagement DESC) AS engagement_ranking
FROM 
    overall_engagement
ORDER BY 
    engagement_ranking;



-- Subjective Question 2
-- For inactive users, what strategies would you recommend to re-engage them 
-- and encourage them to start posting or engaging again?

WITH last_activity AS (
    SELECT u.id AS user_id,
        MAX(
        CASE WHEN l.created_at>=c.created_at AND l.created_at>=p.created_dat THEN l.created_at
			WHEN c.created_at>=p.created_dat THEN c.created_at
            ELSE p.created_dat
		END
        ) AS last_activity_date
    FROM 
        users u
    LEFT JOIN 
        likes l ON u.id = l.user_id
    LEFT JOIN 
        comments c ON u.id = c.user_id
    LEFT JOIN 
        photos p ON u.id = p.user_id
    GROUP BY 
        u.id
)
SELECT 
    u.id,
    u.username,
    la.last_activity_date
FROM 
    users u
JOIN 
    last_activity la ON u.id = la.user_id
ORDER BY last_activity_date;




-- Subjective Question 3
-- Which hashtags or content topics have the highest engagement rates?
--  How can this information guide content strategy and ad campaigns?


WITH likes_per_tag AS( 
	SELECT pt.tag_id,p.id photo_id, 
		COUNT(l.user_id) as number_of_likes 
    FROM photo_tags pt JOIN photos p ON pt.photo_id = p.id 
		JOIN likes l ON p.id = l.photo_id 
    GROUP BY pt.tag_id,p.id
),
comments_per_tag AS( 
	SELECT pt.tag_id,p.id photo_id, 
		COUNT(c.user_id) as number_of_comments 
    FROM photo_tags pt JOIN photos p ON pt.photo_id = p.id 
		JOIN comments c ON p.id = c.photo_id 
    GROUP BY pt.tag_id,p.id
)
,
total_engagement_per_tag AS( 
	SELECT lpt.tag_id, lpt.photo_id, 
		COALESCE(lpt.number_of_likes,0) + COALESCE(cpt.number_of_comments,0)  as total_engagement
    FROM likes_per_tag lpt 
		JOIN comments_per_tag cpt ON lpt.tag_id = cpt.tag_id
			AND lpt.photo_id = cpt.photo_id 
)
SELECT t.tag_name,
	ROUND(AVG(a.total_engagement),2) avg_engagement_per_tag  
FROM total_engagement_per_tag a JOIN tags t ON a.tag_id = t.id 
GROUP BY a.tag_id
ORDER BY AVG(a.total_engagement) DESC;


-- Subjective Question 5
-- Based on follower counts and engagement rates, which users
-- would be ideal candidates for influencer marketing campaigns? 
-- How would you approach and collaborate with these influencers?


WITH followers AS (
	SELECT u.id AS user_id, username, COUNT(*) AS followers_cnt
	FROM users u LEFT JOIN follows f ON u.id=f.followee_id
	GROUP BY u.id
),
likes_received AS (
    SELECT p.user_id, COUNT(*) AS likes_cnt
    FROM likes l
    JOIN photos p ON l.photo_id = p.id
    GROUP BY p.user_id
),
comments_received AS (
    SELECT p.user_id, COUNT(*) AS comments_cnt
    FROM comments c
    JOIN photos p ON c.photo_id = p.id
    GROUP BY p.user_id
)
SELECT f.user_id, username, 
	f.followers_cnt,
    COALESCE(lr.likes_cnt,0) + COALESCE(cr.comments_cnt,0) AS total_engagement,
    RANK() OVER (ORDER BY 
					f.followers_cnt DESC, 
                    COALESCE(lr.likes_cnt,0) + COALESCE(cr.comments_cnt,0) DESC) user_ranking
FROM followers f LEFT JOIN likes_received lr ON f.user_id=lr.user_id
LEFT JOIN comments_received cr ON f.user_id=cr.user_id;

-- Subjective Question 6
-- Based on user behavior and engagement data, how would you
-- segment the user base for targeted marketing campaigns or personalized recommendations?


WITH likes_per_tag AS( 
	SELECT l.user_id, pt.tag_id, 
		COUNT(l.photo_id) AS number_of_likes 
    FROM photo_tags pt JOIN photos p ON pt.photo_id = p.id 
		JOIN likes l ON p.id = l.photo_id 
    GROUP BY l.user_id, pt.tag_id
    ORDER BY l.user_id
),
comments_per_tag AS( 
	SELECT c.user_id, pt.tag_id, 
		COUNT(c.photo_id) AS number_of_comments 
    FROM photo_tags pt JOIN photos p ON pt.photo_id = p.id 
		JOIN comments c ON p.id = c.photo_id 
    GROUP BY c.user_id, pt.tag_id
    ORDER BY c.user_id
),
posts_per_tag AS( 
	SELECT p.user_id, pt.tag_id, 
		COUNT(p.id) AS number_of_posts 
    FROM photo_tags pt JOIN photos p ON pt.photo_id = p.id 
    GROUP BY p.user_id, pt.tag_id
    ORDER BY p.user_id
),
user_wise_engagement AS(
	SELECT u.id AS user_id, username, lpt.tag_id,
		lpt.number_of_likes,
        cpt.number_of_comments,
        ppt.number_of_posts,
        (number_of_likes + number_of_comments + number_of_posts) total_engagement,
        DENSE_RANK() 
			OVER (PARTITION BY u.id ORDER BY (number_of_likes + number_of_comments + number_of_posts) DESC)
            user_content_rank
	FROM users u JOIN  likes_per_tag lpt ON u.id=lpt.user_id
	JOIN  comments_per_tag cpt ON lpt.user_id=cpt.user_id AND lpt.tag_id=cpt.tag_id
    JOIN  posts_per_tag ppt ON lpt.user_id=ppt.user_id AND lpt.tag_id=ppt.tag_id
)
SELECT username,tag_name, number_of_likes, number_of_comments, number_of_posts, total_engagement,
user_content_rank
FROM user_wise_engagement a JOIN tags t ON a.tag_id=t.id
WHERE user_content_rank<=3
ORDER BY username;


-- Subjective Question 10
-- Assuming there's a "User_Interactions" table tracking user engagements,
-- how can you update the "Engagement_Type" column to change all instances
-- of "Like" to "Heart" to align with Instagram's terminology?


-- UPDATE User_Interactions
-- SET Engagement_Type = "Heart"
-- WHERE LOWER(Engagement_Type) = "like";




