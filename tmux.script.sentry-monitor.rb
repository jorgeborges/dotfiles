#!/usr/bin/env ruby

require 'rest-client'
require 'json'
require 'yaml'
require 'fileutils'
require 'uri'

# --- Configuration ---
CONFIG = YAML.load_file(File.join(__dir__, 'config/sentry.yml'))
TOKEN = CONFIG['personal_access_token']
ORG_SLUG = CONFIG['organization_slug']
PROJECTS = CONFIG['projects']
SLACK_WEBHOOK_URL = CONFIG['slack_webhook_url']
SENTRY_API_BASE_URL = "https://sentry.io/api/0/projects"

# --- Caching & Rate Limiting ---
EXECUTION_INTERVAL_SECONDS = 300 # 5 minutes
TMP_DIR = File.join(__dir__, 'tmp')
STATE_FILE = File.join(TMP_DIR, 'sentry_monitor.state')
LAST_RUN_FILE = File.join(TMP_DIR, 'sentry_monitor.lastrun')
LAST_OUTPUT_FILE = File.join(TMP_DIR, 'sentry_monitor.lastoutput')

FileUtils.mkdir_p(TMP_DIR)

# --- Rate-Limiting Logic ---
current_time = Time.now.to_i
last_run_time = File.exist?(LAST_RUN_FILE) ? File.read(LAST_RUN_FILE).to_i : 0

if (current_time - last_run_time) < EXECUTION_INTERVAL_SECONDS && File.exist?(LAST_OUTPUT_FILE)
  puts File.read(LAST_OUTPUT_FILE)
  exit 0
end

# --- State Management ---
def load_issues_from_state
  return [] unless File.exist?(STATE_FILE)
  JSON.parse(File.read(STATE_FILE))
rescue JSON::ParserError
  []
end

def save_issues_to_state(issues)
  issues_to_save = issues.map do |issue|
    { 'id' => issue['id'], 'title' => issue['title'], 'project_slug' => issue['project']['slug'] }
  end
  File.write(STATE_FILE, JSON.pretty_generate(issues_to_save))
end

# --- Slack Notifications ---
def send_new_issue_notification(issue)
  issue_url = "https://#{ORG_SLUG}.sentry.io/issues/#{issue['id']}/"
  message = { text: ":sentry: :red_circle: *New Sentry Issue in `#{issue['project']['slug']}`*\n> <#{issue_url}|#{issue['title']}>" }
  RestClient.post(SLACK_WEBHOOK_URL, message.to_json, { content_type: :json })
end

def send_resolved_issue_notification(issue)
  issue_url = "https://#{ORG_SLUG}.sentry.io/issues/#{issue['id']}/"
  message = { text: ":sentry: :white_check_mark: *Resolved Sentry Issue in `#{issue['project_slug']}`*\n> <#{issue_url}|#{issue['title']}>" }
  RestClient.post(SLACK_WEBHOOK_URL, message.to_json, { content_type: :json })
end

# --- Main Logic ---
begin
  # 1. Fetch all active issues from Sentry across all projects
  all_active_issues = []
  PROJECTS.each do |project_slug|
    query = 'is:unresolved !issue.category:performance'
    url = "#{SENTRY_API_BASE_URL}/#{ORG_SLUG}/#{project_slug}/issues/?query=#{URI.encode_www_form_component(query)}"
    headers = { Authorization: "Bearer #{TOKEN}" }
    response = RestClient.get(url, headers)
    all_active_issues.concat(JSON.parse(response.body))
  rescue RestClient::ExceptionWithResponse => e
    next # Continue to next project if one fails
  end

  # 2. Load previously seen issues from our state file
  previously_seen_issues = load_issues_from_state

  # 3. Get IDs for easy comparison
  active_issue_ids = all_active_issues.map { |issue| issue['id'] }
  previous_issue_ids = previously_seen_issues.map { |issue| issue['id'] }

  # 4. Find what's new and what's resolved
  new_issue_ids = active_issue_ids - previous_issue_ids
  resolved_issue_ids = previous_issue_ids - active_issue_ids

  # 5. Send notifications
  all_active_issues.each { |issue| send_new_issue_notification(issue) if new_issue_ids.include?(issue['id']) }
  previously_seen_issues.each { |issue| send_resolved_issue_notification(issue) if resolved_issue_ids.include?(issue['id']) }

  # 6. Save the new, current state (the single source of truth from Sentry)
  save_issues_to_state(all_active_issues)

  # 7. Prepare and cache output
  active_issue_count = all_active_issues.length
  tmux_output = if active_issue_count > 0
                  "#[fg=red]PO-Sentry: #{active_issue_count} open!#[fg=default]"
                else
                  "PO-Sentry: OK"
                end
  puts tmux_output

  File.write(LAST_RUN_FILE, current_time)
  File.write(LAST_OUTPUT_FILE, tmux_output)

rescue => e
  tmux_output = "#[fg=red]PO-Sentry: Error#[fg=default]"
  puts tmux_output
  File.write(LAST_RUN_FILE, current_time) # Update timestamp even on error to prevent spamming a failing script
  File.write(LAST_OUTPUT_FILE, tmux_output)
end
