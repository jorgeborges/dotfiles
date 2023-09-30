#!/usr/bin/env ruby

require 'rest-client'
require 'json'
require 'yaml'

module NotionTask
  STATUS_CONFIG = {
    "Not started" => {emoji: " ", color: :gray},
    "Ready to start" => {emoji: "\uf9fd", color: :gray},
    "Scheduled" => {emoji: "﯑ ", color: :yellow},
    "In progress" => {emoji: " ", color: :blue}
  }

  class Client
    NOTION_API_URL = "https://api.notion.com/v1/databases"

    def initialize(config)
      @config = config
    end

    def fetch_tasks
      body = construct_request_body
      response = make_api_request(body)
      JSON.parse(response.body)["results"]
    end

    private

    def construct_request_body
      {
        "filter": {
          "and": [
            {
              "property": "Assignee",
              "people": {
                "contains": @config['user_id']
              }
            },
            {
              "or": STATUS_CONFIG.keys.map do |status|
                {
                  "property": "Status",
                  "status": {
                    "equals": status
                  }
                }
              end
            }
          ]
        }
      }
    end

    def make_api_request(body)
      url = "#{NOTION_API_URL}/#{@config['database_id']}/query"
      headers = {
        :Authorization => 'Bearer ' + @config['integration_secret'],
        :content_type => :json,
        :accept => :json,
        'Notion-Version' => '2022-06-28'
      }

      begin
        RestClient.post(url, body.to_json, headers)
      rescue RestClient::ExceptionWithResponse => e
        puts 'Failed to fetch data from Notion API.'
        Kernel.abort
      end
    end
  end

  class Processor
    def initialize
      @status_counts = Hash.new(0)
      STATUS_CONFIG.keys.each { |status| @status_counts[status] = 0 }
    end

    def process(tasks)
      tasks.each do |task|
        status_name = task["properties"]["Status"]["status"]["name"]
        @status_counts[status_name] += 1 if @status_counts.key?(status_name)
      end
      @status_counts
    end
  end

  class Reporter
    def initialize(status_counts)
      @status_counts = status_counts
    end

    def display
      output = @status_counts.map do |status, count|
        emoji = STATUS_CONFIG[status][:emoji]
        color = STATUS_CONFIG[status][:color]
        colorize(emoji + count.to_s, color)
      end.join(" ")

      puts output
    end

    private

    def colorize(text, color)
      colors = {
        gray: "#[fg=darkgray]",
        yellow: "#[fg=yellow]",
        blue: "#[fg=blue]"
      }
      "#{colors[color]}#{text}#[fg=default]"
    end
  end
end

# Main program
config = YAML.load_file(__dir__ + '/config/notion.yml')

client = NotionTask::Client.new(config)
tasks = client.fetch_tasks

processor = NotionTask::Processor.new
status_counts = processor.process(tasks)

reporter = NotionTask::Reporter.new(status_counts)
reporter.display
