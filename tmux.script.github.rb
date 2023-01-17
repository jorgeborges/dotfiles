#!/usr/bin/env ruby

# Gets pull requests created and assigned to me, also my pending reviews
# Outputs icons with total counts

require 'octokit'
require 'yaml'

config = YAML.load_file(__dir__ + '/config/github.yml')

client = Octokit::Client.new(access_token: config['personal_access_token'])

query = <<-GRAPHQL
query {
  user(login: "#{config['my_username']}") {
    pullRequests(first: 100, states: OPEN) {
      totalCount
      nodes {
        author {
          login
        }
        createdAt
        number
        databaseId
        title
        assignees(first: 15) {
          nodes {
            login
          }
        }
        reviewRequests(first: 15) {
          nodes {
            requestedReviewer {
              ... on User {
                login
              }
              ... on Team {
                login: name
              }
            }
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
  puts 'network_error'
  Kernel.abort
end

ignore_review_for_merge_requests_ids = config['ignore_review_for_merge_requests_ids']

begin
  pr_review = 0
  pr_assigned = 0
  response.data.user.pullRequests.nodes.each do |pull_request|
    pull_request.reviewRequests.nodes.each do |review_request|
      if review_request.requestedReviewer.login == config['my_username'] || review_request.requestedReviewer.login == config['my_team']
        pr_review += 1 unless ignore_review_for_merge_requests_ids.include? pull_request.databaseId
      end
    end

    if pull_request.author.login == config['my_username']
      pr_assigned += 1
      next
    end

    pull_request.assignees.nodes.each do |assignee|
      pr_assigned += 1 if assignee.login == config['my_username']
    end
  end
rescue
  puts 'parse_error'
  Kernel.abort
end

puts '#[fg=green]華' + pr_assigned.to_s + ' #[fg=yellow] ' + pr_review.to_s
