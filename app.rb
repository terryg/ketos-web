require 'sinatra'
require 'oauth'
require 'haml'
require 'omniauth'
require 'omniauth-twitter'
require 'rest-client'
require 'json'

class App < Sinatra::Base
  enable :sessions

  get "/" do
    if session[:auth_token].nil?
      haml :register
    else
      haml :home
    end
  end

  get "/register" do
    haml :register
  end

  post "/register" do
    if params[:email].nil? or params[:password].nil?
      haml :register
      return
    end

    response = RestClient.post('http://localhost:5000/register',
                               {
                                 :email => params[:email],
                                 :password => params[:password]
                               })
    case response.code
    when 200
      json = JSON.parse(response.body)
      session[:auth_token] = json['token']
      redirect "/"
    else
      haml :register
    end
  end

  get "/signin" do
    haml :signin
  end

  post "/signin" do
    if params[:email].nil? or params[:password].nil?
      haml :signin
      return
    end

    response = RestClient.post('http://localhost:5000/signin',
                               {
                                 :email => params[:email],
                                 :password => params[:password]
                               })
    case response.code
    when 200
      json = JSON.parse(response.body)
      session[:auth_token] = json['token']
      redirect "/"
    else
      haml :signin
    end
  end

end
