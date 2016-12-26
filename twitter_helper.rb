# Helper methods for the twitter-search application.
module TwitterHelper
  def config_twitter
    yaml_config = YAML.load_file('config.yaml')

    Twitter::REST::Client.new do |config|
      config.consumer_key = yaml_config['twitter_client']['consumer_key']
      config.consumer_secret = yaml_config['twitter_client']['consumer_secret']
      config.access_token = yaml_config['twitter_client']['access_token']
      config.access_token_secret = yaml_config['twitter_client']['access_token_secret']
    end
  end

  def fetch_tweets(keyword, client)
    tweets = client.search(keyword, result_type: 'recent')

    tweets.map do |tweet|
      { time: tweet.created_at,
        name: tweet.user.screen_name,
        text: tweet.text }
    end
  end

  def get_retweets(tweets)
    retweets = []

    if !tweets.first[:text].nil?
      tweets.each do |tweet|
        retweets.push tweet if tweet[:text].start_with? 'RT'
      end
    else
      tweets.each do |tweet|
        retweets.push tweet if tweet['text'].start_with? 'RT'
      end
    end

    retweets
  end

  def save_tweets(tweets, redis)
    key = SecureRandom.hex

    redis.set(key, tweets.to_json)

    key
  end

  def error_handler(message)
    case message
    when 'Missing or invalid url parameter.'
      "Invalid input. Special characters alone aren't allowed! Please try again..."
    when 'Query parameters are missing.'
      "You seem to have entered nothing. Whitespaces alone aren't allowed. Please try again..."
    when 'execution expired'
      'Timed Out! Please try again...'
    else
      "#{message}. Please try again..."
    end
  end

  def take_tweets(key, redis)
    JSON.parse(redis.get(key))
  end

  def filter_today(tweets)
    filtered_tweets = []

    tweets.each do |tweet|
      filtered_tweets.push tweet if tweet['time'].to_date == Date.today
    end

    filtered_tweets
  end

  def filter_five_days(tweets)
    filtered_tweets = []

    tweets.each do |tweet|
      filtered_tweets.push tweet if tweet['time'].to_date > (Date.today - 5.days)
    end

    filtered_tweets
  end

  def filter_before_five_days(tweets)
    filtered_tweets = []

    tweets.each do |tweet|
      filtered_tweets.push tweet if tweet['time'].to_date <= (Date.today - 5.days)
    end

    filtered_tweets
  end

  def filter_tweets(tweets, filter_option)
    case filter_option
    when 'today'
      filter_today(tweets)
    when 'last_five_days'
      filter_five_days(tweets)
    when 'before_five_days'
      filter_before_five_days(tweets)
    else
      tweets
    end
  end
end
