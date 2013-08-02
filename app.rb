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
      json = JSON.parse(response.body)
      puts "**** auth. token [#{json['token']}]"
      session[:auth_token] = json['token']
      redirect to("http://#{request.host}:#{request.port}"), 303
    else
      haml :login
    end
  end

  get '/auth/:provider/callback' do
    auth_hash = request.env['omniauth.auth']
    session[params[:provider]] = {}
    session[params[:provider]][:token] = auth_hash[:credentials][:token]
    session[params[:provider]][:token_secret] = auth_hash[:credentials][:secret]
    redirect(to("http://#{request.host}:#{request.port}"), 303)
  end

  # FAIL
  get '/auth/failure' do
    redirect(to("http://#{request.host}:#{request.port}"), 303)
  end

end
