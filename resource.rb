require 'restclient'

module GooglePlus

  # A modular extension for classes that make requests to the
  # Google Plus API
  module Resource

    # Make a request to an external resource
    def make_request(method, resource, params = {})
			puts params[:access_token]
      # Put together the common params
      params[:key] ||= GooglePlus.api_key unless GooglePlus.api_key.nil?
      params[:userIp] = params.delete(:user_ip) if params.has_key?(:user_ip)
      params[:pp] = '0' # google documentation is incorrect, it says 'prettyPrint'
      # Add the access token if we have it
      headers = {}
      if token = params[:access_token] || GooglePlus.access_token
        headers[:Authorization] = "OAuth #{token}"
      end
      # And make the request
      begin
				if method == :get
          RestClient.get "#{BASE_URI}#{resource}", headers.merge(:params => params)
				elsif method == :post
					RestClient.post "#{BASE_URI}#{resource}", headers.merge(:params => params)
				end
      rescue RestClient::Unauthorized, RestClient::Forbidden, RestClient::BadRequest => e
        raise GooglePlus::RequestError.new(e)
      rescue SocketError => e
        raise GooglePlus::ConnectionError.new(e)
      rescue RestClient::ResourceNotFound
        nil
      end
    end

  end

end