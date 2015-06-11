require 'google_plus'

require './models/feed_bot'
require './models/item'

class GooglePlusBot < FeedBot

  def post(body)
		begin
			puts "**** Accessing googleplus to insert moment..."
			#moment = GooglePlus::Moment.insert("me", "vault", {:items => [{:description => body}], :access_token => @token}  )
			puts moment.attributes
			puts "**** Done."
		rescue => e
      puts "**** There was an error with googleplus -> #{e} ****"
      grams = []
    end
  end

	def load_items(last_id)
    begin
      puts "**** Accessing googleplus feed..."
			puts "**** with #{@token}"
			person = GooglePlus::Person.get("me", :key => "AIzaSyD1qYeO9tuC5c1AzD7Pdi1gL76is3AvmYw") # @token)
			cursor = person.list_activities
      puts "**** Done."
    rescue => e
      puts "**** There was an error with googleplus -> #{e} ****"
      grams = []
    end

    @items = []

		cursor.each do |a|
			@items << Item.new(a, false)
    end

    return 0
  end

end
