class FeedBot

	def initialize(token)
		@token = token
		@items = []
	end

	def items
		return @items
	end

	def post(body)
    raise NotImplementedError, "Implement this method in a child class"
	end

	def load_items(last_id, auth_token)
    raise NotImplementedError, "Implement this method in a child class"
	end
end