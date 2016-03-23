require 'sinatra'
require 'json'
require 'dalli'

set :cache, Dalli::Client.new(ENV["MEMCACHIER_SERVERS"], {
  username: ENV["MEMCACHIER_USERNAME"],
  password: ENV["MEMCACHIER_PASSWORD"]
})

# define with: heroku config:set INTERVAL=<seconds>
INTERVAL = ENV.fetch('INTERVAL', 6).to_i

def last_meow
  settings.cache.get('last_meow') || Time.now
end

def too_soon?
  (last_meow + INTERVAL) >= Time.now
end

def update_points(user_name, points)
  actual = settings.cache.get(user_name) || 0
  settings.cache.set(user_name, actual + points)
  actual + points
end

post '/meow' do
  content_type :json

  if too_soon?
    settings.cache.set('last_meow', Time.now)
    { text: "Hey, wait! It's still too soon to meow. Now the timer has been reset! Wait more #{INTERVAL} seconds before meow." }.to_json
  else
    elapsed_time = Time.now - last_meow
    current_winner = params['user_name']
    current_points = update_points(current_winner, elapsed_time)

    settings.cache.set("last_meow", Time.now)
    { text: "Congratz, #{current_winner}! You are the current meower. You have #{current_points} points"}.to_json
  end
end

post '/meow_command' do
  if params["text"] == 'ranking' 
    return {text: "In the future there will be a ranking listed."}.to_json
  end
end
