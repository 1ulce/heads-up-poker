require 'redis'
Redis.current =  ""
if ENV['RAILS_ENV'] == "development"
  Redis.current = Redis.new(:host => '127.0.0.1', :port => 6379)
else
  Redis.current = Redis.new(:url => ENV['REDIS_URL'])
end
Redis.current