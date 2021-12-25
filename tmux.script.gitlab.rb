#!/usr/bin/env ruby

# Gets merge requests assignned to me and pending reviews
# Outputs icons with total counts

require 'rest-client' # has to be gem installed
require 'json'
require 'date'
require 'yaml'

config = YAML.load_file(__dir__ + '/config/gitlab.yml')

merge_request_type = ARGV[0]

gitlab_api_base_url = 'https://gitlab.com/api/v4/merge_requests'
headers = {:Authorization => 'Bearer ' + config['personal_access_token']}
username = config['my_username']

begin
  case merge_request_type
  when 'assigned'
    response = RestClient.get gitlab_api_base_url + '?scope=assigned_to_me&state=opened', headers
  when 'review'
    response = RestClient.get gitlab_api_base_url + '?scope=all&state=opened&reviewer_username=' + username, headers
  else
    raise 'Invalid argument'
  end
  rescue
    puts 'gitlab_display()'
    Kernel.abort
end

gitlab = JSON.parse response
merge_request_count = gitlab.length()

merge_request_icons = {
  assigned: '華',
  review: ' ',
}

puts merge_request_icons[ARGV[0].to_sym] + merge_request_count.to_s
