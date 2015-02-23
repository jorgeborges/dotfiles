#!/usr/bin/env ruby

# Gets all the account information from Todoist via API call
# Keeps and uses a cache set to CACHE_EXPIRE_SECONDS
# Outputs to Std something like ◯ 12 depending on the argument passed from console

require 'rest_client'
require 'redis'
require 'date'
require 'yaml'

TODOIST_KEY = 'todoist'
CACHE_EXPIRE_SECONDS = 600

config = YAML.load_file(__dir__ + '/config/todoist.yml')

redis = Redis.new
cache_response = redis.get TODOIST_KEY

if cache_response.nil?
  begin
    response = RestClient.post 'https://api.todoist.com/TodoistSync/v5.3/get', :seq_no => '0', :api_token => config['api_token']
  rescue
    if ARGV[0] == 'overdue'
      puts 'task_display()'
    else
      puts '.'
    end
    Kernel.abort
  end
  redis.set TODOIST_KEY, response
  redis.expire TODOIST_KEY, CACHE_EXPIRE_SECONDS
else
  response = cache_response
end

todoist = JSON.parse(response)

overdue = today = future = icebox = 0
todoist['Items'].each do |item|
  if item['due_date'].nil?
    icebox += 1
  else
    if Date.parse(item['due_date']) < Date.today
      overdue += 1
    elsif Date.parse(item['due_date']) == Date.today
      today += 1
    else
      future += 1
    end
  end
end

totals = {
    :overdue => '◯ ' + overdue.to_s,
    :today => '✕ ' + today.to_s,
    :future => ' ⃤ '+ future.to_s,
    :icebox => '△ ' + icebox.to_s,
}

puts totals[ARGV[0].to_sym]
