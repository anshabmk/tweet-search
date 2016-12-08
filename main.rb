require 'sinatra'
require 'twitter'
require 'active_support/all'
require 'json'
require 'redis'
require 'securerandom'

redis = Redis.new

END {
  redis.keys.each {|key| redis.del key }
  puts "All redis keys deleted."
}

client = Twitter::REST::Client.new do |config|
  config.consumer_key = "mhCWQ6xD08VXMIylJIZ98AXxh"
  config.consumer_secret = "aawJm8w2XLrbHQO6SxYgKY4ii7ElNH97i4zGDx7V3IrCrQvAIR"
  config.access_token = "800644619465670656-P832RHheNPDqT9zECCQyn6ZQPIYjwLa"
  config.access_token_secret = "mrLqeqVgiziDK3P0aQPI5euBkvxkS8ANGflN1OSp2SlGs"
end

get '/' do
  error_message = ""
  erb :index, :locals => { :error_message => error_message }
end

post '/' do

  begin
    tweets = client.search(params[:keyword], :result_type => "recent")
  rescue Twitter::Error::Forbidden => e
    p e.message
    error_message = "Your input was invalid. Special characters alone aren't allowed! Please try again..."
    erb :index, :locals => { :error_message => error_message }
  rescue Twitter::Error::BadRequest => e
    p e.message
    error_message = "You seem to have entered nothing. Whitespaces alone aren't allowed. Please try again..."
    erb :index, :locals => { :error_message => error_message }
  rescue Twitter::Error => e
    p e.message
    error_message = "Timed Out! Please try again..."
    erb :index, :locals => { :error_message => error_message }
  else
    key = SecureRandom.hex
    tweets_hash = tweets.map { |tweet| { time: tweet.created_at, name: tweet.user.screen_name, text: tweet.text } }
    retweets = 0
    redis.set(key,tweets_hash.to_json)

    tweets.each do |tweet|
      retweets += 1 if tweet.text.start_with? "RT"
    end
    erb :dashboard, :locals => { :tweets => tweets, :retweets => retweets, :key => key }
  end

end

post '/results' do
  key = params[:key]
  tweets = JSON.parse(redis.get(key))
  retweets = []
  filtered_tweets = []
  tweets_retweets = params[:tweets_retweets]

  tweets.each do |tweet|
    retweets.push tweet if tweet["text"].start_with? "RT"
  end

  if tweets_retweets == "retweets"
    case params[:filter_option]
    when "today"
      retweets.each do |tweet|
        filtered_tweets.push tweet if tweet["time"].to_date == Date.today
      end
    when "last_five_days"
      retweets.each do |tweet|
        filtered_tweets.push tweet if tweet["time"].to_date > (Date.today - 5.days)
      end
    when "before_five_days"
      retweets.each do |tweet|
        filtered_tweets.push tweet if tweet["time"].to_date <= (Date.today - 5.days)
      end
    else
      retweets.each do |tweet|
        filtered_tweets.push tweet
      end
    end
  else
    case params[:filter_option]
    when "today"
      tweets.each do |tweet|
        filtered_tweets.push tweet if tweet["time"].to_date == Date.today
      end
    when "last_five_days"
      tweets.each do |tweet|
        filtered_tweets.push tweet if tweet["time"].to_date > (Date.today - 5.days)
      end
    when "before_five_days"
      tweets.each do |tweet|
        filtered_tweets.push tweet if tweet["time"].to_date <= (Date.today - 5.days)
      end
    else
      tweets.each do |tweet|
        filtered_tweets.push tweet
      end
    end
  end

  erb :results, :locals => { :filtered_tweets => filtered_tweets, :key => key, :tweets_retweets => tweets_retweets }
end
