require 'sinatra'
require 'json'
require 'dalli'

set :cache, Dalli::Client.new(ENV["MEMCACHIER_SERVERS"], {
  username: ENV["MEMCACHIER_USERNAME"],
  password: ENV["MEMCACHIER_PASSWORD"]
})

# User list hash
# {
#   username_1: {points: float, last_meow: Time},
#   username_2: {points: float, last_meow: Time}
# }

# define with: heroku config:set INTERVAL=<seconds>
INTERVAL = ENV.fetch('INTERVAL', 6).to_i

def last_meow
  settings.cache.get('last_meow') || Time.now
end

def too_soon?
  (last_meow + INTERVAL) >= Time.now
end

def update_points(user_name, points)
  if user_list = settings.cache.get(user_list) # would be false only the first time, when there is no memcached object
    if user_list[user_name]
      user_list[user_name][:points] += 1 
    else
      user_list[username] = { points: points, last_meow: Time.now }    
    end
  else
    user_list = {}
    user_list[username] = { points: points, last_meow: Time.now }    
  end
  settings.cache.set('user_list', user_list)
  user_list[username][:points]
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
