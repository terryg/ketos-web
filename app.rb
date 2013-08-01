require 'sinatra'
require 'oauth'
require 'haml'
require 'omniauth'
require 'omniauth-twitter'
require 'omniauth-tumblr'
require 'rest-client'
require 'json'

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
    session[:access_token] = auth_hash[:credentials][:token]
    session[:access_token_secret] = auth_hash[:credentials][:secret]
    redirect '/'
  end

  get '/auth/failure' do
    redirect '/'
  end

end
