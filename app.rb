require 'sinatra'
require 'json'
require 'dalli'

@cache = Dalli::Client.new((ENV["MEMCACHIER_SERVERS"] || "").split(","),
                    {:username => ENV["MEMCACHIER_USERNAME"],
                     :password => ENV["MEMCACHIER_PASSWORD"],
                     :failover => true,
                     :socket_timeout => 1.5,
                     :socket_failure_delay => 0.2
                    })

# define with: heroku config:set INTERVAL=<seconds>
INTERVAL=ENV["INTERVAL"]

def too_soon?
  interval = Time.now - @cache.get("last_meow")
  return interval <= INTERVAL
end

def update_points(user_name)
  actual = @cache.get(user_name) || 0
  @cache.set(user_name, actual+1)
  return actual+1
end

post '/meow' do
  content_type :json
  if too_soon? 
    @cache.set("last_meow", Time.now)
    return { text: "Hey, wait! It's still too soon to meow. Now the timer has been reset! Wait more #{INTERVAL} seconds before meow." }.to_json
  else 
    @cache.set("last_meow", Time.now)
    current_winner = params["user_name"]
    current_points = update_points(current_winner)
    {text: "Congratz, #{current_winner}! You are the current meower. You have #{current_points}"}.to_json
  end
end