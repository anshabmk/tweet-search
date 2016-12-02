require 'sinatra'
require 'twitter'
require 'active_support/all'
require 'json'
#require 'redis'

#redis = Redis.new

client = Twitter::REST::Client.new do |config|
	config.consumer_key = "mhCWQ6xD08VXMIylJIZ98AXxh"
	config.consumer_secret = "aawJm8w2XLrbHQO6SxYgKY4ii7ElNH97i4zGDx7V3IrCrQvAIR"
	config.access_token = "800644619465670656-P832RHheNPDqT9zECCQyn6ZQPIYjwLa"
	config.access_token_secret = "mrLqeqVgiziDK3P0aQPI5euBkvxkS8ANGflN1OSp2SlGs"
end

get '/' do
  erb :index
end

post '/' do
  retweets = []
  tweets = client.search(params[:keyword], :result_type => "recent").take(100).collect

	tweets_hash = tweets.map { |tweet| { time: tweet.created_at, name: tweet.user.screen_name, text: tweet.text } }

#	redis.set("#{params[:keyword]}",tweets_hash.to_json)

  tweets.each do |tweet|
    retweets.push tweet if tweet.text.start_with? "RT"
  end

  erb :dashboard, :locals => { :tweets_hash => tweets,:retweets => retweets }
end

post '/results' do
	tweets = JSON.parse params[:tweets]

	erb :results, :locals => { :tweets => tweets }
end

post '/results/filter' do
  filtered_tweets = []

  case params[:filter_option]
  when "retweets"
    @@tweets.each do |tweet|
      filtered_tweets.push tweet if tweet.text.start_with? "RT"
    end
  when "today"
    @@tweets.each do |tweet|
      filtered_tweets.push tweet if tweet.created_at.to_date == Date.today
    end
  when "last_five_days"
    @@tweets.each do |tweet|
      filtered_tweets.push tweet if tweet.created_at.to_date > (Date.today - 5.days)
    end
  when "before_five_days"
    @@tweets.each do |tweet|
      filtered_tweets.push tweet if tweet.created_at.to_date <= (Date.today - 5.days)
    end
  when "retweets_today"
    @@retweets.each do |tweet|
      filtered_tweets.push tweet if tweet.created_at.to_date == Date.today
    end
  when "retweets_last_five_days"
    @@retweets.each do |tweet|
      filtered_tweets.push tweet if tweet.created_at.to_date > (Date.today - 5.days)
    end
  when "retweets_before_five_days"
    @@retweets.each do |tweet|
      filtered_tweets.push tweet if tweet.created_at.to_date <= (Date.today - 5.days)
    end
  end

  erb :filter, :locals => {:filtered_tweets => filtered_tweets}
end
