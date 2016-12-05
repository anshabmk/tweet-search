# Twitter Search Interface using Search API
This application contains :

An Interface to monitor a keyword in Twitter (Using Twitter search API)
===================================================
(Implemented using sinatra)

1st Phase
----------
1. An interface to enter the keyword
2. A dashboard to monitor the activities
    1. Number of unique users tweeting about the keyword.
    2. Number of tweets
    3. Number of retweets

3. A report page with filter that shows all the tweets
    filter values:
    1. tweet/retweet
    2. Date of tweet

Values are stored in Redis database with different keys generated for each search that makes the collected data(tweets) remains unaffected even if more than one search are done at the same time. 
