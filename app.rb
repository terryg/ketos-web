require 'sinatra'
require 'oauth'
require 'haml'
require 'omniauth'
require 'omniauth-twitter'
require 'omniauth-tumblr'
require 'omniauth-facebook'
require 'rest-client'
require 'json'
require 'twitter'
require 'koala'

require './item'
require './twitter_bot'

class App < Sinatra::Base
  enable :sessions

  configure :development, :test do
    set :host, 'localhost:3000'
    set :force_ssl, false
    OmniAuth.config.full_host = 'http://localhost:3000'
  end
  configure :staging do
    set :host, 'ketos-web-staging.herokuapp.com'
    set :force_ssl, true
  end
  configure :production do
    set :host, 'ketos-web.herokuapp.com'
    set :force_ssl, true
  end

  use OmniAuth::Builder do
    provider :facebook, ENV['FACEBOOK_CONSUMER_KEY'], ENV['FACEBOOK_CONSUMER_SECRET'], :scope => 'read_stream', :display => 'popup'
    provider :tumblr, ENV['TUMBLR_CONSUMER_KEY'], ENV['TUMBLR_CONSUMER_SECRET']
    provider :twitter, ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET']
  end

  get '/' do
    if session[:auth_token].nil?
      haml :register
    else
      
      @items = []

      if session[:twitter]
        twit_bot = TwitterBot.new(session[:twitter][:token],
                                  session[:twitter][:token_secret])

        last_id = session[:twitter][:last_id] || 0
        session[:twitter][:last_id] = twit_bot.get_tweets(last_id,
                                                          session[:auth_token])

        @items.concat(twit_bot.items)
      end # if session[:twitter]

      if session[:facebook]
        graph = Koala::Facebook::API.new(session[:facebook][:token])
        puts "**** Accessing FB feed..."
        begin
          feed = graph.get_connections("me", "home")
        rescue Koala::Facebook::APIError => e
          puts "**** there was a problem"
          puts "**** #{e.response_body}"
          puts "**** #{e.message}"
          feed = []
          session[:facebook] = nil
        end
        puts "**** Done."
        session[:facebook][:last_created_time] ||= 0
        ids_to_save = []
        feed.each do |f|
          # :BUG: 20130905 tgl: not ready for prime time
          @items << Item.new(f, false)
        end
        
      end # if session['facebook']

      @items.sort_by!{ |i| i.created_at }
      @items.reverse!
      @items.each do |i|
        i.store(session[:auth_token])
      end

      @refresh = "on"
      
      puts "**** All done, start rendering #{@items.size} items."
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
          
          json['providers'].each do |p|
            j = JSON.parse(p)
            
            puts "***** here is #{j['provider']}"
            
            session[j['provider']] = {}
            session[j['provider']][:token] = j['access_token']
            session[j['provider']][:token_secret] = j['access_token_secret']
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

  get '/auth/:provider/callback' do
    auth_hash = request.env['omniauth.auth']

    puts "**** /auth/#{params[:provider]}/callback"
    puts "**** #{auth_hash}"

    provider = params[:provider]
    session[provider] = {}
    session[provider][:token] = auth_hash[:credentials][:token]
    session[provider][:token_secret] = auth_hash[:credentials][:secret]


    
    response = RestClient.post("#{ENV['KETOS_URL']}/provider",
                               {
                                 :token => session[:auth_token],
                                 :uid => auth_hash[:uid],
                                 :provider => provider,
                                 :access_token => auth_hash[:credentials][:token],
                                 :access_token_secret => auth_hash[:credentials][:secret]
                               })
    puts "**** provider #{response.body}"
    redirect(to("http://#{request.host}:#{request.port}"), 303)
  end

  # FAIL
  get '/auth/failure' do
    redirect(to("http://#{request.host}:#{request.port}"), 303)
  end

end
