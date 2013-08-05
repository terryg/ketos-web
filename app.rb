require 'sinatra'
require 'oauth'
require 'haml'
require 'omniauth'
require 'omniauth-twitter'
require 'omniauth-tumblr'
require 'omniauth-facebook'
require 'rest-client'
require 'json'

class App < Sinatra::Base
  enable :sessions

  configure :development, :test do
    set :host, 'localhost:5000'
    set :force_ssl, false
    OmniAuth.config.full_host = 'http://localhost:5000'
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
    provider :facebook, ENV['FACEBOOK_CONSUMER_KEY'], ENV['FACEBOOK_CONSUMER_SECRET']
    provider :tumblr, ENV['TUMBLR_CONSUMER_KEY'], ENV['TUMBLR_CONSUMER_SECRET']
    provider :twitter, ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET']
  end

  get '/' do
    if session[:auth_token].nil?
      haml :register
    else

      @tweets = {}

      if session['twitter']
        puts "**** session [#{session}]"
        puts "**** session['twitter'] [#{session['twitter']}]"
        puts "**** session[:twitter] [#{session[:twitter]}]"

        Twitter.configure do |config|
          config.consumer_key = ENV['TWITTER_CONSUMER_KEY']
          config.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
          config.oauth_token = session['twitter'][:token]
          config.oauth_token_secret = session['twitter'][:token_secret]
        end

        @tweets = Twitter.home_timeline

        @tweets.each do |t|
          response = RestClient.post("#{ENV['KETOS_URL']}/item",
                                     {
                                       :token => session[:auth_token],
                                       :text => t.full_text
                                     })
        end

      end

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

    if params[:email].nil? or params[:password].nil?
      haml :login
      return
    end

    puts "**** log in to [#{ENV['KETOS_URL']}/signin]"
    response = RestClient.post("#{ENV['KETOS_URL']}/signin",
                               {
                                 :email => params[:email],
                                 :password => params[:password]
                               })
    case response.code
    when 200
      puts "****  response from signin #{response.body}"
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
    else
      haml :login
    end
  end

  get '/logout' do
    session.clear
    redirect '/'
  end

  get '/auth/:provider/callback' do
    auth_hash = request.env['omniauth.auth']

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
