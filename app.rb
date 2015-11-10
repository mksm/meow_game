require 'sinatra'
require 'json'
require 'dalli'
set :cache, Dalli::Client.new(ENV["MEMCACHIER_SERVERS"],
                  {:username => ENV["MEMCACHIER_USERNAME"],
                   :password => ENV["MEMCACHIER_PASSWORD"]})

# define with: heroku config:set INTERVAL=<seconds>
INTERVAL=ENV["INTERVAL"]

def too_soon?
  if 
  interval = Time.now - (settings.cache.get("last_meow") || Time.now-1)
  return interval <= INTERVAL.to_i
end

def update_points(user_name)
  actual = settings.cache.get(user_name) || 0
  settings.cache.set(user_name, actual+1)
  return actual+1
end

post '/meow' do
  content_type :json
  if too_soon? 
    settings.cache.set("last_meow", Time.now)
    return { text: "Hey, wait! It's still too soon to meow. Now the timer has been reset! Wait more #{INTERVAL} seconds before meow." }.to_json
  else 
    settings.cache.set("last_meow", Time.now)
    current_winner = params["user_name"]
    current_points = update_points(current_winner)
    {text: "Congratz, #{current_winner}! You are the current meower. You have #{current_points}"}.to_json
  end
end