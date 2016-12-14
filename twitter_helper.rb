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
end
