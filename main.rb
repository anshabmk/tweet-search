require 'sinatra'
require 'twitter'
require 'active_support/all'
require 'json'
require 'redis'
require 'securerandom'
require 'yaml'

redis = Redis.new

def read_twitter_config
  config = YAML.load_file('config.yaml')
  @consumer_key = config['twitter_client']['consumer_key']
  @consumer_secret = config['twitter_client']['consumer_secret']
  @access_token = config['twitter_client']['access_token']
  @access_token_secret = config['twitter_client']['access_token_secret']
end

read_twitter_config

client = Twitter::REST::Client.new do |config|
  config.consumer_key = @consumer_key
  config.consumer_secret = @consumer_secret
  config.access_token = @access_token
  config.access_token_secret = @access_token_secret
end

get '/' do
  error_message = ''
  erb :index, locals: { error_message: error_message }
end

post '/' do
  key = SecureRandom.hex
  begin
    tweets = client.search(params[:keyword], result_type: 'recent')
    tweets_hash = tweets.map { |tweet| { time: tweet.created_at, name: tweet.user.screen_name, text: tweet.text } }
    retweets_count = 0
    redis.set(key, tweets_hash.to_json)
    tweets.each { |tweet| retweets_count += 1 if tweet.text.start_with? 'RT' }

    erb :dashboard, locals: { tweets: tweets, retweets_count: retweets_count, key: key }
  rescue Twitter::Error::Forbidden => e
    p e.message
    error_message = "Your input was invalid. Special characters alone aren't allowed! Please try again..."
    erb :index, locals: { error_message: error_message }
  rescue Twitter::Error::BadRequest => e
    p e.message
    error_message = "You seem to have entered nothing. Whitespaces alone aren't allowed. Please try again..."
    erb :index, locals: { error_message: error_message }
  rescue Twitter::Error => e
    p e.message
    error_message = 'Timed Out! Please try again...'
    erb :index, locals: { error_message: error_message }
  end
end

post '/results' do
  key = params[:key]
  tweets = JSON.parse(redis.get(key))
  retweets = []
  filtered_tweets = []
  tweets_retweets = params[:tweets_retweets]

  tweets.each { |tweet| retweets.push tweet if tweet['text'].start_with? 'RT' }

  if tweets_retweets == 'retweets'
    case params[:filter_option]
    when 'today'
      retweets.each { |tweet| filtered_tweets.push tweet if tweet['time'].to_date == Date.today }
    when 'last_five_days'
      retweets.each { |tweet| filtered_tweets.push tweet if tweet['time'].to_date > (Date.today - 5.days) }
    when 'before_five_days'
      retweets.each { |tweet| filtered_tweets.push tweet if tweet['time'].to_date <= (Date.today - 5.days) }
    else
      retweets.each { |tweet| filtered_tweets.push tweet }
    end
  else
    case params[:filter_option]
    when 'today'
      tweets.each { |tweet| filtered_tweets.push tweet if tweet['time'].to_date == Date.today }
    when 'last_five_days'
      tweets.each { |tweet| filtered_tweets.push tweet if tweet['time'].to_date > (Date.today - 5.days) }
    when 'before_five_days'
      tweets.each { |tweet| filtered_tweets.push tweet if tweet['time'].to_date <= (Date.today - 5.days) }
    else
      tweets.each { |tweet| filtered_tweets.push tweet }
    end
  end

  erb :results, locals: { filtered_tweets: filtered_tweets, key: key, tweets_retweets: tweets_retweets }
end
