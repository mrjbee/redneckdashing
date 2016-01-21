# Using API call similar to following
# https://ci.jenkins-ci.org/view/All/job/infra_update_center_v3/lastBuild/api/json


require 'net/http'
require 'json'
require 'openssl'

class JenkinsJobStatus
  def initialize(display_name, timestamp_human_str, progress, url)
    @display_name=display_name
    @timestamp_human_str=timestamp_human_str
    @progress=progress
    @url = url
  end
  def to_s # called with print / puts
    "Job name = #{@display_name}, timestamp = #{@timestamp_human_str}, progress = #{@progress}, url = #{@url} "
  end

  def is_fail
     @progress == -1
  end

  def is_over_time
     @progress > 1
  end
  def progress_human
    progress = (@progress * 100).round
    progress = [100, progress].min
    progress = [0, progress].max
    progress
  end
end


module Jenkins
   def Jenkins.lastJobStatus(server_url, job_name)
        jenkins_url = URI.parse(server_url)
        job_url_str = "/job/#{job_name}/lastBuild/api/json?pretty=true"
        #puts "Requested job url = #{jenkins_url+job_url_str}"
        http = Net::HTTP.new(jenkins_url.host, jenkins_url.port)
        request = Net::HTTP::Get.new(job_url_str)
        if server_url.start_with?('https')
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        response = http.request(request)
        job_json_obj = JSON.parse(response.body)

        date = Time.at(job_json_obj['timestamp']/1000).to_datetime
        date_str = date.strftime("%m/%d/%Y at %I:%M%p")
        progress = case job_json_obj['result']
           when nil then
              #maybe negative if something wrong with locale (which isnt case of unixtime)
              in_progress_secconds = Time.now.to_i - job_json_obj['timestamp']/1000
              estimated_duration = job_json_obj['estimatedDuration']/1000
              progress = in_progress_secconds.to_f/[estimated_duration, 1].max
              # puts "Progress #{in_progress_secconds}, estimate #{estimated_duration} => progress = #{progress}"
              progress
           when "SUCCESS" then 1.0
           when "FAILURE" then -1.0
           when "UNSTABLE" then -1.0
           else raise "unexpected result = #{job_json_obj['result']}"
        end

        JenkinsJobStatus.new(job_json_obj['displayName'], date_str, progress, job_json_obj['url']);
   end
end