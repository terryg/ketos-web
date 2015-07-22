
require 'sinatra'
require 'oauth'
require 'haml'
require 'omniauth'
require 'omniauth-twitter'
require 'omniauth-tumblr'
require 'omniauth-instagram'
require 'omniauth-facebook'
require 'omniauth-google-oauth2'
require 'omniauth-linkedin'
require 'rest-client'
require 'json'
require 'twitter'
require 'tumblr_client'
require 'koala'

require './models/item'
require './models/feed_bot_factory'
require './models/twitter_bot'
require './models/tumblr_bot'
require './models/facebook_bot'
require './models/instagram_bot'
require './models/google_plus_bot'

class App < Sinatra::Base
	use Rack::Session::Cookie, :key => 'rack.session', :secret => ENV['RACK_SESSION_SECRET']
	enable :methodoverride

  configure :development, :test do
    set :host, 'skeely-framed.codio.io:3000'
    set :force_ssl, false
    OmniAuth.config.full_host = 'http://skeely-framed.codio.io:3000'
  end
  configure :staging do
    set :host, 'ketos-web-staging.herokuapp.com'
    set :force_ssl, true
  end
  configure :qa do
    set :host, 'ketos-web-qa.herokuapp.com'
    set :force_ssl, true
  end
  configure :production do
    set :host, 'ketos-web.herokuapp.com'
    set :force_ssl, true
  end

  use OmniAuth::Builder do
    provider :facebook, ENV['FACEBOOK_CONSUMER_KEY'], ENV['FACEBOOK_CONSUMER_SECRET'], :scope => 'user_posts,read_stream,publish_actions', :display => 'popup'
    provider :tumblr, ENV['TUMBLR_CONSUMER_KEY'], ENV['TUMBLR_CONSUMER_SECRET']
    provider :twitter, ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET']
		provider :google_oauth2, ENV['GOOGLEPLUS_CONSUMER_KEY'], ENV['GOOGLEPLUS_CONSUMER_SECRET'], :scope => 'plus.login,plus.me'
		provider :linkedin, ENV['LINKEDIN_CONSUMER_KEY'], ENV['LINKEDIN_CONSUMER_SECRET']
		provider :instagram, ENV['INSTAGRAM_CONSUMER_KEY'], ENV['INSTAGRAM_CONSUMER_SECRET']
  end

  before do
    if request.env['HTTP_HOST'].match(/herokuapp\.com/)
      redirect 'http://www.ketosapp.com', 301
    end

    if session[:auth_token].nil? && !['/', '/login', '/register'].include?(request.path_info)
      redirect '/'
    end

    @providers = PROVIDERS
    @active = []
		PROVIDERS.each do |p|
			if session[p]
        @active << p
			end
    end
  end

	PROVIDERS = ['twitter', 'tumblr', 'facebook', 'google_oauth2', 'instagram', 'linkedin', 'pinterest']

  post '/' do
    if session[:auth_token].nil?
      haml :register
    else
      body = params[:body]

      puts "**** POST '/'"
      puts params
      
			@active.each do |active|
				puts "**** #{active}: #{params[active]}"
			  puts "**** session has [#{session[active]}]"

		    if session[active] and params[active] == "on"
					puts "**** in session and on"
  	   
					factory = FeedBotFactory.new(active, session)
					bot = factory.make(session[active])
   
	        puts "**** Posting..."

					if params[:media] and params[:media][:tempfile]
		  			bot.post_file(params[:media][:tempfile])
			  	else       
				    bot.post(body)
				  end

  				puts "**** Done."
        end
    	end
  
      @path = '/'
      haml :home
    end
  end

  get '/' do
    if session[:auth_token].nil?
      haml :register
    else    
			@path = '/'
      haml :home
    end
  end
  
  get '/register' do
    haml :register
  end

  post '/register' do
    if params[:email].nil? or params[:password].nil?
      haml :register
      return
    end

    puts "**** register with [#{ENV['KETOS_URL']}/register]"
    response = RestClient.post("#{ENV['KETOS_URL']}/register",
                               {
                                 :email => params[:email],
                                 :password => params[:password]
                               })
    case response.code
    when 200
      json = JSON.parse(response.body)
      puts "**** auth. token [#{json['token']}]"
      session[:auth_token] = json['token']
      redirect(to("http://#{request.host}:#{request.port}"), 303)
    else
      haml :register
    end
  end

  get '/login' do
    haml :login
  end

  post '/login' do
    session.clear

    if !params[:email].empty? and !params[:password].empty?
      puts "**** log in to [#{ENV['KETOS_URL']}/signin]"

      resource = RestClient::Resource.new("#{ENV['KETOS_URL']}/signin",
                                          :timeout => -1)
      payload = {:email => params[:email],:password => params[:password]}.to_json
      resource.post(payload) { |response, req, result, &block|
        puts "****  response code from signin #{response.code}"
        puts "****  response from signin #{response.body}"
      
        case response.code
        when 200
          json = JSON.parse(response.body)
          puts "**** auth. token [#{json['token']}]"
          session[:auth_token] = json['token']

          session.options[:expire_after] = 2592000 unless params[:remember].nil? # 30.days
          
          json['providers'].each do |p|
            j = JSON.parse(p)
            
            puts "***** here is #{j['provider']}"
            
            session[j['provider']] = {}
            session[j['provider']][:token] = j['access_token']
            session[j['provider']][:token_secret] = j['access_token_secret']
            session[j['provider']][:uid] = j['uid']
          end
          
          redirect to("http://#{request.host}:#{request.port}"), 303
        when 401
          @error_message = "E-mail or password is incorrect."          
        end
      }

    end

    haml :login
  end

  get '/logout' do
    session.clear
    redirect '/'
  end

  get '/account' do
    haml :account
  end

  delete '/account/delete/:provider' do
    response = RestClient.delete("#{ENV['KETOS_URL']}/provider/delete/#{params[:provider]}",
                                 :headers => {'Authorization' => "Token #{session[:auth_token]}"})
    puts "**** provider delete #{response.code}"
    case response.code
    when 200
      session[params[:provider].to_sym] = nil
    end
    redirect '/account'
  end

  get '/auth/:provider/callback' do
    auth_hash = request.env['omniauth.auth']

    puts "**** /auth/#{params[:provider]}/callback"
    puts "**** #{auth_hash} ****"

    provider = params[:provider]
    session[provider] = {}
    session[provider][:token] = auth_hash[:credentials][:token]
    session[provider][:token_secret] = auth_hash[:credentials][:secret]
    
    response = RestClient.post("#{ENV['KETOS_URL']}/provider/create/#{provider}",
                               {
                                 :token => session[:auth_token],
                                 :uid => auth_hash[:uid],
                                 :access_token => auth_hash[:credentials][:token],
                                 :access_token_secret => auth_hash[:credentials][:secret]
                               })
    puts "**** provider #{response.body}"

    if provider == "tumblr"
      @blogs = []
      auth_hash[:extra][:raw_info][:blogs].each do |b|
        @blogs << b[:name]
      end

      if @blogs.size > 1
        haml :tumblr
      else
        redirect(to("http://#{request.host}:#{request.port}"), 303)
      end
    else
      redirect(to("http://#{request.host}:#{request.port}"), 303)
    end
  end

  # FAIL
  get '/auth/failure' do
    redirect(to("http://#{request.host}:#{request.port}"), 303)
  end
  
  post "/tumblr" do
    unless session[:auth_token].nil?
      response = RestClient.put("#{ENV['KETOS_URL']}/provider/update/tumblr",
                                { :uid => params[:blogname] },
                                { :headers => {'Authorization' => "Token #{session[:auth_token]}"}})
      puts "**** provider put #{response.code}"
      case response.code
      when 200
        session[:tumblr][:uid] = params[:blogname]
      end
    end
    redirect(to("http://#{request.host}:#{request.port}"), 303)
  end

  get '/count' do
    content_type :json
		{:count => 42}.to_json
  end

  get '/fetch' do

  end

  get "/feed/:provider" do
    items = []

		puts "**** #{params[:provider]} #{session[params[:provider]]}"

    if session[params[:provider]]
			puts "**** in session"
  	  factory = FeedBotFactory.new(params[:provider], session)
	    bot = factory.make(session[params[:provider]])
   
	    puts "**** feed of #{params[:provider]}"

      last_id = session[params[:provider]][:last_id] || 0
      session[params[:provider]][:last_id] = bot.load_items(last_id, session[:auth_token])

      puts "**** for #{bot.items.size} items"
		  items = bot.items
    end

    content_type :json
    items.map{ |o| o.to_json }.to_json
  end

  post "/feed/twitter/retweet/:id" do
    if session[:twitter]
      twit_bot = TwitterBot.new(session[:twitter][:token],
                                session[:twitter][:token_secret])
			twit_bot.retweet(params[:id])
		end
    redirect(to("http://#{request.host}:#{request.port}"), 303)
	end  

  protected
  
end
