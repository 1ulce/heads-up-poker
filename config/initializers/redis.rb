require 'redis'
$redis =  ""
if ENV['RAILS_ENV'] == "development"
  $redis = Redis.new(:host => '127.0.0.1', :port => 6379)
else
  $redis = Redis.new(:url => ENV['REDIS_URL'])
end
Redis::Objects.redis = $redis