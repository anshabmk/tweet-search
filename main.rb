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

	@@retweets = []
	@@tweets = client.search(params[:keyword], :result_type => "recent").take(100).collect
	@@tweets.each do |tweet|
		if tweet.text.start_with? "RT"
			@@retweets.push tweet
		end
	end

	erb :dashboard
end

get '/results' do

	erb :results
end

post '/results/filter' do

	@@filterArray = []
	@filterVal = params[:filterOption]
	case @filterVal
		when "1"
			@@tweets.each do |tweet|
				if tweet.text.start_with? "RT"
					@@filterArray.push tweet
				end
			end
		when "2"
			@@tweets.each do |tweet|
				if tweet.created_at.strftime("%F") == Date.today.strftime("%F")
					@@filterArray.push tweet
				end
			end
		when "3"
			@@tweets.each do |tweet|
				if tweet.created_at.strftime("%F") > ((Date.today)-5).strftime("%F")
					@@filterArray.push tweet
				end
			end
		when "4"
			@@tweets.each do |tweet|
				if tweet.created_at.strftime("%F") <= ((Date.today)-5).strftime("%F")
					@@filterArray.push tweet
				end
			end
		when "11"
			@@retweets.each do |tweet|
				if tweet.created_at.strftime("%F") == Date.today.strftime("%F")
					@@filterArray.push tweet
				end
			end
		when "12"
			@@retweets.each do |tweet|
				if tweet.created_at.strftime("%F") > ((Date.today)-5).strftime("%F")
					@@filterArray.push tweet
				end
			end
		when "13"
			@@retweets.each do |tweet|
				if tweet.created_at.strftime("%F") <= ((Date.today)-5).strftime("%F")
					@@filterArray.push tweet
				end
			end
	end

	erb :filter
end
