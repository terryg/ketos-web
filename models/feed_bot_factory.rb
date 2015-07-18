require './models/facebook_bot.rb'
require './models/google_plus_bot.rb'
require './models/instagram_bot.rb'
require './models/tumblr_bot.rb'
require './models/twitter_bot.rb'

class FeedBotFactory

	def initialize(provider, session)
		@provider = provider
		@valid = (not session[@provider].nil?)
	end

	def make(tokens)
		feed_bot = nil

		if @valid == true
			if @provider == "facebook"
				puts "**** FacebookBot.new"
				feed_bot = FacebookBot.new(tokens[:token])
			end
			if @provider == "google_oauth2"
				feed_bot = GooglePlusBot.new(tokens[:token])
			end
			if @provider == "instagram"
				feed_bot = InstagramBot.new(tokens[:token], tokens[:token_secret])
			end
 			if @provider == "tumblr"
				puts "**** Making TumblrBot for #{tokens[:uid]}"
				feed_bot = TumblrBot.new(tokens[:token], tokens[:token_secret])
				feed_bot.uid = tokens[:uid]
			end
 			if @provider == "twitter"
				feed_bot = TwitterBot.new(tokens[:token], tokens[:token_secret])
			end
		end

		return feed_bot
	end

end