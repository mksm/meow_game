require 'sinatra'
require 'json'
# require 'dalli'
# set :cache, Dalli::Client.new

post '/meow' do
  content_type :json
  {text: "Wow, meow!"}.to_json
end