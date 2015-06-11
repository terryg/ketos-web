require './models/google_plus_bot.rb'

class FeedBotFactory

	def initialize(provider, session)
		@provider = provider
		@valid = (not session[@provider].nil?)
	end

	def make(token)
		feed_bot = nil

		if @valid == true
			if @provider == "google_oauth2"
				feed_bot = GooglePlusBot.new(token)
			end
		end

		return feed_bot
	end

end