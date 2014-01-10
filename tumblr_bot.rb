require 'tumblr_client'
require 'json'

class TumblrBot

  def initialize(token, secret)
    @token = token
    @secret = secret
  end

  def items
    return @items
  end

  def post(blogname, body)
    Tumblr.configure do |config|
      config.consumer_key = ENV['TUMBLR_CONSUMER_KEY']
      config.consumer_secret = ENV['TUMBLR_CONSUMER_SECRET']
      config.oauth_token = @token
      config.oauth_token_secret = @secret
    end
  
    begin
      client = Tumblr::Client.new
      client.text("#{blogname}.tumblr.com", {:body => body})
    rescue => e
      puts "**** There was an error with Tumblr -> #{e} ****"
    end

  end

  def get_posts(last_id, auth_token)

    Tumblr.configure do |config|
      config.consumer_key = ENV['TUMBLR_CONSUMER_KEY']
      config.consumer_secret = ENV['TUMBLR_CONSUMER_SECRET']
      config.oauth_token = @token
      config.oauth_token_secret = @secret
    end
  
    begin
      puts "**** Accessing Tumblr feed..."
      client = Tumblr::Client.new
      posts = client.dashboard['posts']
      puts "**** Done."
    rescue => e
      puts "**** There was an error with Tumblr -> #{e} ****"
      posts = []
    end

    @items = []

    last_id ||= 0
    ids_to_save = []
    posts.each do |p|
      if last_id < p['id']
        ids_to_save << p['id']
        need_save = true
      end
      
      @items << Item.new(p, need_save)
    end
    
    @items.each do |i|
      if ids_to_save.include?(i.id)
        response = RestClient.post("#{ENV['KETOS_URL']}/item",
                                   {
                                     :token => auth_token,
                                     :created_at => i.created_at,
                                     :text => i.text
                                   })
        
        if last_id < i.id
          last_id = i.id
        end
      end
    end

    return last_id
  end

end
