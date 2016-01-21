require_relative '../lib/jenkins.rb'

#SCHEDULER.every '2s' do
#end
# https://ci.jenkins-ci.org/view/All/job/infra_update_center_v3/lastBuild/api/json
server_url = "https://ci.jenkins-ci.org"
job_name = "infra_accountapp"
jobDetails = Jenkins.lastJobStatus(server_url, job_name)
puts "Just fetched job = #{jobDetails} using url=#{server_url}"
