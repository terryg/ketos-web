require 'koala'

require './models/item'

class FacebookBot

  def initialize(token)
    @token = token
		@items = []
  end

  def items
    return @items
  end

  def post(body)
    graph = Koala::Facebook::API.new(@token)
		begin
      graph.put_connections("me", "feed", :message => body)
		rescue Koala::Facebook::APIError => e
      puts "**** there was a problem"
      puts "**** #{e.response_body}"
      puts "**** #{e.message}"
      feed = []
    end
  end

	def get_news()
		graph = Koala::Facebook::API.new(@token)
    puts "**** Accessing FB feed..." 
    begin
			feed = graph.get_connections("me", "home")
			
			@items = []

			puts "XXXX #{feed[0]}"
			feed.each do |f|
				@items << Item.new(f, @save)
			end

		rescue Koala::Facebook::APIError => e
      puts "**** there was a problem"
      puts "**** #{e.response_body}"
      puts "**** #{e.message}"
      feed = []
    end
    puts "**** Done."

  end

  def like
  end

end
