require 'sinatra'
require 'twitter'

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

	@re_count = 0
	@@tweets = client.search(params[:keyword], :result_type => "recent").take(1000).collect
	@@tweets.each do |tweet|
		if tweet.text.start_with? "RT"
			@re_count += 1
		end
	end

	erb :dashboard
end

get '/results' do

	erb :results
end

post '/results/filter' do
	@retweets = []
	@filterVal = params[:filterOption]
	@@tweets.each do |tweet|
		if tweet.text.start_with? "RT"
			@retweets.push tweet
		end
	end

	erb :filter
end
