module GooglePlus
	# A Moment in Google Plus
	class Moment

		extend GooglePlus::Resource
		include GooglePlus::Entity

		# Insert a new moment
		# @param [String] user_id the id of the user to record actions for
		# @param [String] collection moment will be written to this collection
		# @option params [Boolean] :debug returns created moment when true
		# @return [GooglePlus::Moment] if the debug option is true, the moment
		#   that was written - otherwise, return nil
		def self.insert(user_id, collection, params = {})
			data = make_request(:post, "people/#{user_id}/moments/#{collection}", params)
			Moment.new(JSON.parse(data)) if data
    end

    # Load a new instance from an attributes hash
    # Useful if you have the underlying response data for an object - Generally, what you
    # want is #get though
		# @return [GooglePlus::Moment] A moment constructed from the attributes hash
    def initialize(hash)
      load_hash(hash)
    end
	end
end