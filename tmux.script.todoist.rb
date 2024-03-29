#!/usr/bin/env ruby

# Gets all the account information from Todoist via API call
# Outputs to Std something like ◯ 12 depending on the argument passed from console

require 'rest-client' # has to be gem installed
require 'json'
require 'date'
require 'yaml'

config = YAML.load_file(__dir__ + '/config/todoist.yml')

begin
  response = RestClient.get 'https://api.todoist.com/rest/v2/tasks', {:Authorization => 'Bearer ' + config['api_token']}
rescue
  if ARGV[0] == 'overdue'
    puts 'task_display()'
  else
    puts '.'
  end
  Kernel.abort
end

todoist = JSON.parse response

overdue = today = future = icebox = 0
todoist.each do |item|
  next if item['is_completed']

  if item['due'].nil?
    icebox += 1
  else
    due_date = Date.parse(item['due']['date'])
    if due_date < Date.today
      overdue += 1
    elsif due_date == Date.today
      today += 1
    # only count non-recurring tasks in the next 7 days as future
    elsif due_date > Date.today && due_date <= Date.today + 7 && item['due']['is_recurring'] == false
      future += 1
    end
  end
end

totals = {
  overdue: ' ' + overdue.to_s,
  today: ' ' + today.to_s,
  future: '﯑ ' + future.to_s,
  icebox: ' ' + icebox.to_s
}

puts totals[ARGV[0].to_sym]
