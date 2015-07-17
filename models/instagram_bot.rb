require 'instagram'

require './models/feed_bot'

class InstagramBot < FeedBot

	def initialize(token)
    @token = token
    @save = false
		Instagram.configure do |config|
			config.client_id = ENV['INSTAGRAM_CONSUMER_KEY']
			config.client_secret = ENV['INSTAGRAM_CONSUMER_SECRET']
		end
  end

  def items
    return @items
  end

  def post(body)

  end

	def load_items(last_id, auth_token)
    begin
      puts "**** Accessing Instagram feed..."
			client = Instagram.client(:access_token => @token)
			user = client.user
			grams = client.user_media_feed(777)
      puts "**** Done."
    rescue => e
      puts "**** There was an error with Instagram -> #{e} ****"
      grams = []
    end

    @items = []

    grams.each do |g|
			@items << Item.new(g, false)
    end

    if @save == true

    end

    return 0
  end

end
