require 'dotenv'
require 'sinatra'
require 'sinatra/reloader'
require 'omniauth'
require 'omniauth-spotify'
require 'json'

Dotenv.load

class SinatraApp < Sinatra::Base
  register Sinatra::Reloader
  configure do
    set :sessions, true
    set :inline_templates, true
  end

  use OmniAuth::Builder do
    provider :spotify,
    ENV['APP_TOKEN'],
    ENV['APP_SECRET_TOKEN'],
    callback_path: "/auth/spotify/callback",
    scope: 'user-read-private playlist-read-private playlist-read-collaborative playlist-modify-public'
  end

  get '/' do
    html = <<-HTML
      <form action="/auth/spotify" method="POST" enctype="multipart/form-data">
          <input type="hidden" name="authenticity_token" value='#{request.env["rack.session"]["csrf"]}'>
          <input type="submit">
      </form>
    HTML
    erb html
  end

  get '/auth/:provider/callback' do
    result = request.env["omniauth.auth"]
    File.open('.env','a') do |f|
      f.write("OAUTH_TOKENS=#{JSON.generate(result)}")
    end
    erb "<a href='/'>Top</a><br>
         <h1>#{params[:provider]}</h1>
         <pre>#{JSON.generate(result)}</pre>"
  end
end

if __FILE__ == $0
  SinatraApp.run!
end
