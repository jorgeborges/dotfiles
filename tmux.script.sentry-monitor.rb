#!/usr/bin/env ruby

require 'rest-client'
require 'json'
require 'yaml'
require 'fileutils'
require 'uri'
require 'socket'

# --- Configuration ---
CONFIG = YAML.load_file(File.join(__dir__, 'config/sentry.yml'))
TOKEN = CONFIG['personal_access_token']
ORG_SLUG = CONFIG['organization_slug']
PROJECTS = CONFIG['projects']
SLACK_WEBHOOK_URL = CONFIG['slack_webhook_url']
SENTRY_API_BASE_URL = "https://sentry.io/api/0/projects"

# --- Caching & Rate Limiting ---
EXECUTION_INTERVAL_SECONDS = 150 # 2.5 minutes
FETCH_MAX_ATTEMPTS = 3
FETCH_RETRY_BACKOFF_SECONDS = [0.5, 1.0].freeze

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

# --- Issue shape helpers (API response vs persisted state row) ---
def issue_project_slug(issue)
  issue.dig('project', 'slug') || issue['project_slug']
end

def state_row_from_api(issue)
  { 'id' => issue['id'], 'title' => issue['title'], 'project_slug' => issue_project_slug(issue) }
end

def api_shape_from_state_row(row)
  { 'id' => row['id'], 'title' => row['title'], 'project' => { 'slug' => row['project_slug'] } }
end

# --- State Management ---
def load_issues_from_state
  return [] unless File.exist?(STATE_FILE)
  JSON.parse(File.read(STATE_FILE))
rescue JSON::ParserError
  []
end

def save_issues_to_state(issues)
  issues_to_save = issues.map { |issue| state_row_from_api(issue) }
  File.write(STATE_FILE, JSON.pretty_generate(issues_to_save))
end

# --- Sentry API ---
def fetch_issues_for_project(project_slug)
  query = 'is:unresolved issue.category:error'
  url = "#{SENTRY_API_BASE_URL}/#{ORG_SLUG}/#{project_slug}/issues/?query=#{URI.encode_www_form_component(query)}"
  headers = { Authorization: "Bearer #{TOKEN}" }

  FETCH_MAX_ATTEMPTS.times do |attempt|
    begin
      response = RestClient.get(url, headers)
      parsed = JSON.parse(response.body)
      return { success: true, issues: parsed } if parsed.is_a?(Array)
    rescue JSON::ParserError, RestClient::ExceptionWithResponse, RestClient::Exception, SocketError,
           Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::ETIMEDOUT, Errno::EHOSTUNREACH
      # retry
    end
    sleep FETCH_RETRY_BACKOFF_SECONDS[attempt] if attempt < FETCH_MAX_ATTEMPTS - 1
  end
  { success: false, issues: [] }
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
  previously_seen_issues = load_issues_from_state
  previous_by_slug = previously_seen_issues.group_by { |r| r['project_slug'] }

  merged = []
  failed_slugs = []

  PROJECTS.each do |project_slug|
    result = fetch_issues_for_project(project_slug)
    if result[:success]
      merged.concat(result[:issues])
    else
      failed_slugs << project_slug
      (previous_by_slug[project_slug] || []).each do |row|
        merged << api_shape_from_state_row(row)
      end
    end
  end

  merged.uniq! { |i| i['id'].to_s }

  merged_ids = merged.map { |issue| issue['id'] }
  previous_issue_ids = previously_seen_issues.map { |issue| issue['id'] }

  new_issue_ids = merged_ids - previous_issue_ids
  resolved_issue_ids = previous_issue_ids - merged_ids

  merged.each { |issue| send_new_issue_notification(issue) if new_issue_ids.include?(issue['id']) }
  previously_seen_issues.each { |issue| send_resolved_issue_notification(issue) if resolved_issue_ids.include?(issue['id']) }

  save_issues_to_state(merged)

  open_count = merged.length
  tmux_output = if open_count > 0
                  if failed_slugs.any?
                    "#[fg=red]PO-Sentry: #{open_count} open#[fg=yellow] (stale)#[fg=default]"
                  else
                    "#[fg=red]PO-Sentry: #{open_count} open!#[fg=default]"
                  end
                elsif failed_slugs.any?
                  "#[fg=yellow]PO-Sentry: 0 open (stale)#[fg=default]"
                else
                  "#[fg=green]PO-Sentry "
                end
  puts tmux_output

  File.write(LAST_RUN_FILE, current_time)
  File.write(LAST_OUTPUT_FILE, tmux_output)

rescue StandardError
  tmux_output = "#[fg=red]PO-Sentry: Error#[fg=default]"
  puts tmux_output
  File.write(LAST_RUN_FILE, current_time) # Update timestamp even on error to prevent spamming a failing script
  File.write(LAST_OUTPUT_FILE, tmux_output)
end
