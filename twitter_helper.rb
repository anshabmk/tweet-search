# Helper methods for the twitter-search application.
module TwitterHelper
  def self.configure
    yaml_config = YAML.load_file('config.yaml')
    Twitter::REST::Client.new do |config|
      config.consumer_key = yaml_config['twitter_client']['consumer_key']
      config.consumer_secret = yaml_config['twitter_client']['consumer_secret']
      config.access_token = yaml_config['twitter_client']['access_token']
      config.access_token_secret = yaml_config['twitter_client']['access_token_secret']
    end
  end

  def self.fetch_tweets(keyword, client)
    tweets = client.search(keyword, result_type: 'recent')
    tweets.map { |tweet| { time: tweet.created_at, name: tweet.user.screen_name, text: tweet.text } }
  end

  def self.get_retweets(tweets)
    retweets = []
    if !tweets.first[:text].nil?
      tweets.each { |tweet| retweets.push tweet if tweet[:text].start_with? 'RT' }
    else
      tweets.each { |tweet| retweets.push tweet if tweet['text'].start_with? 'RT' }
    end
    return retweets
  end

  def self.save_tweets(tweets, redis)
    key = SecureRandom.hex
    redis.set(key, tweets.to_json)
    return key
  end

  def self.error_handler(message)
    p message
    case message
    when 'Missing or invalid url parameter.'
      "Invalid input. Special characters alone aren't allowed! Please try again..."
    when 'Query parameters are missing.'
      "You seem to have entered nothing. Whitespaces alone aren't allowed. Please try again..."
    when 'execution expired.'
      'Timed Out! Please try again...'
    end
  end

  def self.take_tweets(key, redis)
    JSON.parse(redis.get(key))
  end

  def self.filter_tweets(tweets, filter_option)
    filtered_tweets = []
    case filter_option
    when 'today'
      tweets.each { |tweet| filtered_tweets.push tweet if tweet['time'].to_date == Date.today }
    when 'last_five_days'
      tweets.each { |tweet| filtered_tweets.push tweet if tweet['time'].to_date > (Date.today - 5.days) }
    when 'before_five_days'
      tweets.each { |tweet| filtered_tweets.push tweet if tweet['time'].to_date <= (Date.today - 5.days) }
    else
      tweets.each { |tweet| filtered_tweets.push tweet }
    end
    return filtered_tweets
  end
end
