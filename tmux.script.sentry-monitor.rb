#!/usr/bin/env ruby

require 'rest-client'
require 'json'
require 'yaml'
require 'fileutils'

# --- Configuration ---
CONFIG = YAML.load_file(File.join(__dir__, 'config/sentry.yml'))
TOKEN = CONFIG['personal_access_token']
ORG_SLUG = CONFIG['organization_slug']
PROJECTS = CONFIG['projects']
SLACK_WEBHOOK_URL = CONFIG['slack_webhook_url']
SENTRY_API_BASE_URL = "https://sentry.io/api/0/projects"

STATE_FILE = File.join(__dir__, 'tmp', 'sentry_monitor.state')

# --- State Management ---
def load_seen_group_ids
  return [] unless File.exist?(STATE_FILE)
  JSON.parse(File.read(STATE_FILE))
rescue JSON::ParserError
  []
end

def save_seen_group_ids(ids)
  FileUtils.mkdir_p(File.dirname(STATE_FILE))
  File.write(STATE_FILE, JSON.pretty_generate(ids.uniq))
end

# --- Slack Notification ---
def send_slack_notification(project_slug, event)
  group_id = event['groupID']
  title = event['title']
  issue_url = "https://#{ORG_SLUG}.sentry.io/issues/#{group_id}/"

  message = {
    text: ":sentry: *New Sentry Issue in `#{project_slug}`*\n> <#{issue_url}|#{title}>"
  }

  RestClient.post(SLACK_WEBHOOK_URL, message.to_json, { content_type: :json })
rescue RestClient::ExceptionWithResponse => e
  # Suppress errors to not break the tmux bar, but maybe log them somewhere
end

# --- Main Logic ---
begin
  seen_group_ids = load_seen_group_ids
  current_run_group_ids = []

  PROJECTS.each do |project_slug|
    url = "#{SENTRY_API_BASE_URL}/#{ORG_SLUG}/#{project_slug}/events/?statsPeriod=60m"
    headers = { Authorization: "Bearer #{TOKEN}" }

    begin
      response = RestClient.get(url, headers)
      events = JSON.parse(response.body)

      events.each do |event|
        group_id = event['groupID']
        current_run_group_ids << group_id

        unless seen_group_ids.include?(group_id)
          send_slack_notification(project_slug, event)
          seen_group_ids << group_id
        end
      end
    rescue RestClient::ExceptionWithResponse => e
      # Handle API errors for a single project without crashing
      next
    end
  end

  save_seen_group_ids(seen_group_ids)

  # --- Output ---
  active_issue_count = current_run_group_ids.uniq.length

  if active_issue_count > 0
    puts "#[fg=red]PO-Sentry: #{active_issue_count} open!#[fg=default]"
  else
    puts "PO-Sentry: OK"
  end

rescue => e
  puts "#[fg=red]PO-Sentry: Error#[fg=default]"
end
