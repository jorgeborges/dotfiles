#!/usr/bin/env ruby

# Gets all the account information from Todoist via API call
# Keeps and uses a cache set to CACHE_EXPIRE_MINUTES
# Outputs to Std something like ◯ 12 depending on the argument passed from console

require 'rest-client'
require 'json'
require 'redis'
require 'date'
require 'yaml'

TODOIST_KEY = 'todoist'
CACHE_EXPIRE_MINUTES = 10

config = YAML.load_file(__dir__ + '/config/todoist.yml')

redis = Redis.new
response = redis.get TODOIST_KEY

if response.nil?
  begin
    response = RestClient.post 'https://todoist.com/API/v7/sync', {token: config['api_token'], sync_token: '*', resource_types: '["all"]'}
  rescue
    if ARGV[0] == 'overdue'
      puts 'task_display()'
    else
      puts '.'
    end
    Kernel.abort
  end
  redis.set TODOIST_KEY, response, ex: (60 * CACHE_EXPIRE_MINUTES)
end

todoist = JSON.parse response

overdue = today = future = icebox = 0
todoist['items'].each do |item|
  if item['due_date_utc'].nil?
    icebox += 1
  else
    if Date.parse(item['due_date_utc']) < Date.today
      overdue += 1
    elsif Date.parse(item['due_date_utc']) == Date.today
      today += 1
    else
      future += 1
    end
  end
end

totals = {
  overdue: '◯ ' + overdue.to_s,
  today: '✕ ' + today.to_s,
  future: ' ⃤ ' + future.to_s,
  icebox: '△ ' + icebox.to_s
}

puts totals[ARGV[0].to_sym]
