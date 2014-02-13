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
require 'tumblr_client'
require 'koala'

require './item'
require './twitter_bot'
require './tumblr_bot'

class App < Sinatra::Base
  enable :sessions
  enable :methodoverride

  configure :development, :test do
    set :host, 'localhost:3000'
    set :force_ssl, false
    OmniAuth.config.full_host = 'http://localhost:3000'
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
    provider :facebook, ENV['FACEBOOK_CONSUMER_KEY'], ENV['FACEBOOK_CONSUMER_SECRET'], :scope => 'read_stream', :display => 'popup'
    provider :tumblr, ENV['TUMBLR_CONSUMER_KEY'], ENV['TUMBLR_CONSUMER_SECRET']
    provider :twitter, ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET']
  end

  before do
    if request.env['HTTP_HOST'].match(/herokuapp\.com/)
      redirect 'http://www.ketosapp.com', 301
    end

    if session[:auth_token].nil? && !['/', '/login', '/register'].include?(request.path_info)
      redirect '/'
    end
  end

  PROVIDERS = ['twitter', 'tumblr', 'facebook']

  post '/' do
    if session[:auth_token].nil?
      haml :register
    else
      body = params[:body]

      if session[:twitter]
        begin
          puts "**** Twitter in session, posting..."
          twit_bot = TwitterBot.new(session[:twitter][:token],
                                    session[:twitter][:token_secret])
          twit_bot.post(body)
          puts "**** Done."
        rescue => e
          puts "**** Twitter had a problem --> #{e}"
        end
      end

      if session[:tumblr]
        begin
          puts "**** Tumblr in session, posting..."
          tumblr_bot = TumblrBot.new(session[:tumblr][:token],
                                     session[:tumblr][:token_secret])
          tumblr_bot.post(session[:tumblr][:uid], body)
          puts "**** Done."
        rescue => e
          puts "**** Tumblr had a problem --> #{e}"
        end
      end

      if session[:facebook]
        begin
          puts "**** Facebook in session, posting..."
          graph = Koala::Facebook::API.new(session[:facebook][:token])
          graph.put_connections("me", "feed", :message => body)
          puts "**** Done."
        rescue => e
          puts "**** Facebook had a problem --> #{e}"
        end
      end

      @items = make_items
      
      @refresh = "on"
      
      puts "**** All done, start rendering #{@items.size} items."
      haml :home
    end
  end

  get '/' do
    if session[:auth_token].nil?
      haml :register
    else    
      @items = make_items
      
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

          session.options[:expire_after] = 2592000 unless params[:remember].nil? # 30.days
          
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

  get '/account' do
    @providers = []
    PROVIDERS.each do |p|
      @providers << p if session[p]
    end
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

  get '/logout' do
    session.clear
    redirect '/'
  end

  get '/auth/:provider/callback' do
    auth_hash = request.env['omniauth.auth']

    puts "**** /auth/#{params[:provider]}/callback"

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
      session[:tumblr][:blogname] = params[:blogname]
    end
    redirect(to("http://#{request.host}:#{request.port}"), 303)
  end

  protected
  
  def make_items
    items = []
    
    if session[:twitter]
      twit_bot = TwitterBot.new(session[:twitter][:token],
                                session[:twitter][:token_secret])
      
      last_id = session[:twitter][:last_id] || 0
      session[:twitter][:last_id] = twit_bot.get_tweets(last_id,
                                                        session[:auth_token])
      
      items.concat(twit_bot.items)
    end # if session[:twitter]

    if session[:tumblr]
      tumblr_bot = TumblrBot.new(session[:tumblr][:token],
                                 session[:tumblr][:token_secret])
      
      last_id = session[:tumblr][:last_id] || 0
      session[:tumblr][:last_id] = tumblr_bot.get_posts(last_id,
                                                        session[:auth_token])
      
      items.concat(tumblr_bot.items)    
    end # if session[:tumblr]

    if session[:facebook]
      graph = Koala::Facebook::API.new(session[:facebook][:token])
      puts "**** Accessing FB feed..."
      begin
        feed = graph.get_connections("me", "home") 
        
        session[:facebook][:last_created_time] ||= 0
        ids_to_save = []
        feed.each do |f|  
          # :BUG: 20130905 tgl: not ready for saving, set 2nd arg ==
          # false for now
          items << Item.new(f, false)
        end
        
      rescue Koala::Facebook::APIError => e
        puts "**** there was a problem"
        puts "**** #{e.response_body}"
        puts "**** #{e.message}"
        feed = []
        session[:facebook] = nil
      end
      puts "**** Done."
      
    end # if session['facebook']
    
    items.sort_by!{ |i| i.created_at }
    items.reverse!
    items.each do |i|
      i.store(session[:auth_token])
    end
    
    return items
  end
  
end
