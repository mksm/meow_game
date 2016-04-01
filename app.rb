require 'sinatra'
require 'json'
require 'dalli'

set :cache, Dalli::Client.new(ENV["MEMCACHIER_SERVERS"], {
  username: ENV["MEMCACHIER_USERNAME"],
  password: ENV["MEMCACHIER_PASSWORD"]
})

# define with: heroku config:set INTERVAL=<seconds>
INTERVAL = ENV.fetch('INTERVAL', 600).to_i

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

def mark_user_as_known(user_name)
  known_users = settings.cache.get('known_users') || []
  known_users << user_name
  known_users = known_users.uniq
  settings.cache.set('known_users', known_users)
end

post '/meow' do
  content_type :json

  if too_soon?
    settings.cache.set('last_meow', Time.now)
    { text: "Hey, wait! It's still too soon to meow. Now the timer has been reset! Wait more #{INTERVAL} seconds before meow." }.to_json
  else
    elapsed_time = (Time.now - last_meow).to_i
    current_winner = params['user_name']
    current_points = update_points(current_winner, elapsed_time)

    # add user to known_users array
    mark_user_as_known(current_winner)

    settings.cache.set("last_meow", Time.now)
    { text: "Congratz, #{current_winner}! You are the current meower. You have #{current_points} points"}.to_json
  end
end

post '/meow_command' do
  content_type :json

  if params['text'] == 'ranking'
    msg = {
      response_type: 'in_channel',
      text:          'Ranking atualizado dos meow\'ers:',
      attachments:   [
        {
          fields: [
            {
              title: 'Nick',
              short: true
            },
            {
              title: 'Pontos',
              short: true
            }
          ]
        }
      ]
    }

    known_users = settings.cache.get('known_users') || []
    scores = known_users.map { |user| [user, settings.cache.get(user)] }
    scores = scores.sort_by(&:last).reverse

    scores.each do |user, points|
      msg[:attachments][0][:fields] << { value: user,   short: true }
      msg[:attachments][0][:fields] << { value: points, short: true }
    end

    msg.to_json
  end
end
