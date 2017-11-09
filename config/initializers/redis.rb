require 'redis'
if ENV['RAILS_ENV'] == "development"
  Redis.current = Redis.new(:host => '127.0.0.1', :port => 6379)
else
  Redis.current = Redis.new(:host => 'redis://h:pc7bfd9a4468f39f94174fcdd6f6d4c191e12e332f91d71edf4a42176b9df848c@ec2-34-236-65-51.compute-1.amazonaws.com', :port => 63539)
end