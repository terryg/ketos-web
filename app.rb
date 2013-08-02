require 'sinatra'
require 'oauth'
require 'haml'
require 'omniauth'
require 'omniauth-twitter'
require 'omniauth-tumblr'
require 'rest-client'
require 'json'
require 'twitter'

class App < Sinatra::Base
  enable :sessions

  use OmniAuth::Builder do
    provider :tumblr, ENV['TUMBLR_CONSUMER_KEY'], ENV['TUMBLR_CONSUMER_SECRET']
    provider :twitter, ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET']
  end

  get '/' do
    if session[:auth_token].nil?
      haml :register
    else

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

    response = RestClient.post('http://ketos.herokuapp.com/register',
                               {
                                 :email => params[:email],
                                 :password => params[:password]
                               })
    case response.code
    when 200
      json = JSON.parse(response.body)
      session[:auth_token] = json['token']
      redirect '/'
    else
      haml :register
    end
  end

  get '/login' do
    haml :login
  end

  post '/login' do
    if params[:email].nil? or params[:password].nil?
      haml :login
      return
    end

    response = RestClient.post('http://ketos.herokuapp.com/signin',
                               {
                                 :email => params[:email],
                                 :password => params[:password]
                               })
    case response.code
    when 200
      json = JSON.parse(response.body)
      session[:auth_token] = json['token']
      redirect '/'
    else
      haml :login
    end
  end

  get '/auth/:provider/callback' do
    auth_hash = request.env['omniauth.auth']
    provider = params[:provider]
    session[provider] = {}
    session[provider][:token] = auth_hash[:credentials][:token]
    session[provider][:token_secret] = auth_hash[:credentials][:secret]
    redirect '/'
  end

  # FAIL
  get '/auth/failure' do
    redirect '/'
  end

end
