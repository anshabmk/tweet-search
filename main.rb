require 'sinatra'
require 'twitter'
require 'active_support/all'
require 'json'
require 'redis'
require 'securerandom'
require 'yaml'
require_relative 'twitter_helper'

redis = Redis.new
client = TwitterHelper.configure

get '/' do
  error_message = ''
  erb :index, locals: { error_message: error_message }
end

post '/' do
  begin
    tweets = TwitterHelper.fetch_tweets(params[:keyword], client)
    retweets = TwitterHelper.get_retweets(tweets)
    key = TwitterHelper.save_tweets(tweets, redis)
    erb :dashboard, locals: { tweets: tweets, retweets: retweets, key: key }
  rescue Twitter::Error::Forbidden, Twitter::Error::BadRequest, Twitter::Error => e
    error_message = TwitterHelper.error_handler(e.message)
    erb :index, locals: { error_message: error_message }
  end
end

post '/results' do
  key = params[:key]
  tweets_retweets = params[:tweets_retweets]
  tweets = TwitterHelper.take_tweets(key, redis)
  retweets = TwitterHelper.get_retweets(tweets)

  if tweets_retweets == 'retweets'
    filtered_tweets = TwitterHelper.filter_tweets(retweets, params[:filter_option])
  else
    filtered_tweets = TwitterHelper.filter_tweets(tweets, params[:filter_option])
  end

  erb :results, locals: { filtered_tweets: filtered_tweets, key: key, tweets_retweets: tweets_retweets }
end
