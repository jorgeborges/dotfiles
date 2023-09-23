#!/usr/bin/env ruby

require 'rest-client'
require 'json'
require 'yaml'

def colorize(text, color)
  colors = {
    gray: "#[fg=darkgray]",
    yellow: "#[fg=yellow]",
    blue: "#[fg=blue]"
  }
  "#{colors[color]}#{text}#[fg=default]"
end


# Load API configurations for Notion from the YAML file
config = YAML.load_file(__dir__ + '/config/notion.yml')

# Initialize counters for each task status
statuses = {
  "Not started" => 0,
  "Scheduled" => 0,
  "In progress" => 0
}

# Construct the request body for filtering tasks by Assignee and Status
body = {
  "filter": {
    "and": [
      {
        "property": "Assignee",
        "people": {
          "contains": config['user_id']
        }
      },
      {
        "or": [
          {
            "property": "Status",
            "status": {
              "equals": "Not started"
            }
          },
          {
            "property": "Status",
            "status": {
              "equals": "Scheduled"
            }
          },
          {
            "property": "Status",
            "status": {
              "equals": "In progress"
            }
          }
        ]
      }
    ]
  }
}

begin
  # Make the POST request to Notion API
  response = RestClient.post "https://api.notion.com/v1/databases/#{config['database_id']}/query", body.to_json, {
    :Authorization => 'Bearer ' + config['integration_secret'],
    :content_type => :json,
    :accept => :json,
    'Notion-Version' => '2022-06-28'
  }

rescue RestClient::ExceptionWithResponse => e
  puts 'Failed to fetch data from Notion API.'
  Kernel.abort
end

# Parse the response
notion_tasks = JSON.parse(response.body)["results"]

# Count tasks based on their status
notion_tasks.each do |task|
  status_name = task["properties"]["Status"]["status"]["name"]
  statuses[status_name] += 1 if statuses.key?(status_name)
end

# Map statuses to emojis and colors
status_emojis = {
  "Not started" => "",
  "Scheduled" => "﯑",
  "In progress" => ""
}
status_colors = {
  "Not started" => :gray,
  "Scheduled" => :yellow,
  "In progress" => :blue
}

# Print the counts in the desired format
output = statuses.map do |status, count|
  "#{colorize(status_emojis[status] + ' ' + count.to_s, status_colors[status])}"
end.join(" ")

puts output
