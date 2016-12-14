require 'sinatra'
require 'twitter'
require 'active_support/all'
require 'json'
require 'redis'
require 'securerandom'
require 'yaml'
require_relative 'twitter_helper'

include TwitterHelper

redis = Redis.new
client = config_twitter

get '/' do
  error_message = ''
  erb :index, locals: { error_message: error_message }
end

post '/' do
  begin
    tweets = fetch_tweets(params[:keyword], client)
    retweets = get_retweets(tweets)
    key = save_tweets(tweets, redis)
    erb :dashboard, locals: { tweets: tweets, retweets: retweets, key: key }
  rescue Twitter::Error::Forbidden, Twitter::Error::BadRequest, Twitter::Error => e
    error_message = error_handler(e.message)
    erb :index, locals: { error_message: error_message }
  end
end

post '/results' do
  key = params[:key]
  tweets_retweets = params[:tweets_retweets]
  tweets = take_tweets(key, redis)
  retweets = get_retweets(tweets)

  if tweets_retweets == 'retweets'
    filtered_tweets = filter_tweets(retweets, params[:filter_option])
  else
    filtered_tweets = filter_tweets(tweets, params[:filter_option])
  end

  erb :results, locals: { filtered_tweets: filtered_tweets, key: key, tweets_retweets: tweets_retweets }
end
