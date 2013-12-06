require 'twitter'

class TwitterBot

  def initialize(token, secret)
    @token = token
    @secret = secret
  end

  def items
    return @items
  end

  def get_tweets(last_id, auth_token)
    Twitter.configure do |config|
      config.consumer_key = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
      config.oauth_token = @token
      config.oauth_token_secret = @secret
    end
  
    puts "**** Accessing Twitter feed..."
    tweets = Twitter.home_timeline
    puts "**** Done."

    @items = []

    last_id ||= 0
    ids_to_save = []
    tweets.each do |t|
      if last_id < t.id
        ids_to_save << t.id
        need_save = true
      end
      
      @items << Item.new(t, need_save)
    end
    
    tweets.each do |t|
      if ids_to_save.include?(t.id)
        response = RestClient.post("#{ENV['KETOS_URL']}/item",
                                   {
                                     :token => auth_token,
                                     :created_at => t.created_at,
                                     :text => t.full_text
                                   })
        
        if last_id < t.id
          last_id = t.id
        end
      end
    end

    return last_id
  end

end
