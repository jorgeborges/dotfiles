#!/usr/bin/env ruby

# Gets pull requests created and assigned to me, also my pending reviews
# Outputs icons with total counts

require 'time'
require 'colorize'
require 'octokit'
require 'yaml'
require 'awesome_print'

config = YAML.load_file(__dir__ + '/config/github.yml')

client = Octokit::Client.new(access_token: config['personal_access_token'])

display_mode = ARGV[0]

query = <<-GRAPHQL
query {
  user(login: "#{config['my_username']}") {
    pullRequests(first: 100, states: OPEN) {
      totalCount
      nodes {
        repository {
          name
        }
        author {
          login
        }
        createdAt
        number
        databaseId
        title
        url
        assignees(first: 15) {
          nodes {
            login
          }
        }
      }
    }
  }
}
GRAPHQL

begin
  response = client.post '/graphql', { query: query }.to_json
rescue
  puts 'network_error_assigned'
  Kernel.abort
end

begin
  pr_assigned = 0
  pr_assigned_details = []
  response.data.user.pullRequests.nodes.each do |pull_request|
    pr_assigned_details.push({
      repo: pull_request.repository.name,
      number: pull_request.number,
      title: pull_request.title,
      created_at: pull_request.createdAt,
      url: pull_request.url,
    })

    if pull_request.author.login == config['my_username']
      pr_assigned += 1
      next
    end

    pull_request.assignees.nodes.each do |assignee|
      pr_assigned += 1 if assignee.login == config['my_username']
      next
    end
  end
rescue
  puts 'parse_error_assigned'
  Kernel.abort
end

query = <<-GRAPHQL
{
  search(query: "type:pr state:open review-requested:#{config['my_username']}", type: ISSUE, first: 100) {
    issueCount
    edges {
      node {
        ... on PullRequest {
          repository {
            nameWithOwner
          }
          title
          number
          databaseId
          url
          createdAt
        }
      }
    }
  }
}
GRAPHQL

begin
  response = client.post '/graphql', { query: query }.to_json
rescue
  puts 'network_error_review'
  Kernel.abort
end

ignore_review_for_merge_requests_ids = config['ignore_review_for_pull_requests_ids']

begin
  pr_review = 0
  pr_review_details = []
  response.data.search.edges.each do |pull_request|
    if ignore_review_for_merge_requests_ids.include? pull_request.node.databaseId
      next
    end

    pr_review_details.push({
      repo: pull_request.node.repository.nameWithOwner,
      number: pull_request.node.number,
      title: pull_request.node.title,
      url: pull_request.node.url,
      created_at: pull_request.node.createdAt,
    })

    pr_review += 1
  end
rescue
  puts 'parse_error_review'
  Kernel.abort
end

if display_mode == 'status_bar'
  puts '#[fg=green]華' + pr_assigned.to_s + ' #[fg=yellow] ' + pr_review.to_s
elsif display_mode == 'list_details'
  puts 'Github Pull Requests'.colorize(:light_blue)
  puts 'Assigned to me:'.colorize(:light_green)
  if pr_assigned_details.empty? then
    puts '  None'
  end
  pr_assigned_details.each do |pr|
    # puts "  #{pr[:repo]} ##{pr[:number]} - #{pr[:title]} #{DateTime.strptime(pr[:created_at], '%Y-%m-%dT%H:%M:%SZ')} (#{pr[:url]})"
    puts "  #{pr[:repo]} ##{pr[:number]} - #{pr[:title]} #{pr[:created_at]} (#{pr[:url]})"
  end

  if pr_review_details.empty? then
    puts '  None'
  end
  puts 'Pending review:'.colorize(:yellow)
  pr_review_details.each do |pr|
    puts "  #{pr[:repo]} ##{pr[:number]} - #{pr[:title]} #{pr[:created_at]} (#{pr[:url]})"
  end
end
