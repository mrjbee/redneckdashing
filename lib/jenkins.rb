# Using API call similar to following
# https://ci.jenkins-ci.org/view/All/job/infra_update_center_v3/lastBuild/api/json


require 'net/http'
require 'json'
require 'openssl'

class JenkinsJobStatus
  def initialize(original_name, display_name, timestamp_human_str, progress, url)
    @original_name = original_name
    @display_name = display_name
    @timestamp_human_str = timestamp_human_str
    @progress = progress
    @url = url
  end
  def to_s # called with print / puts
    "Job name = #{job_full_name}, timestamp = #{@timestamp_human_str}, progress = #{@progress}, url = #{@url} "
  end

  def job_full_name
    "#{@original_name} (#{@display_name})"
  end

  def is_fail
     @progress == -1
  end

  def is_in_progress
     @progress != 1 &&  @progress != -1
  end

  def is_over_time
     @progress > 1
  end

  def url
     @url
  end

  def progress_human
    progress = (@progress * 100).round
    progress = [100, progress].min
    progress = [0, progress].max
    progress
  end
  def start_at
    @timestamp_human_str
  end
end


module Jenkins
   def Jenkins.lastJobStatus(server_url, job_name)
        jenkins_url = URI.parse(server_url)
        job_url_str = URI::encode("/job/#{job_name}/lastBuild/api/json")
        #puts "Requested job url = #{jenkins_url+job_url_str}"
        http = Net::HTTP.new(jenkins_url.host, jenkins_url.port)
        request = Net::HTTP::Get.new(job_url_str)
        if server_url.start_with?('https')
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        response = http.request(request)
        job_json_obj = JSON.parse(response.body)

        local_offset = Time.now.getlocal.utc_offset/60/60
        date = (Time.at(job_json_obj['timestamp']/1000)) + Rational(local_offset, 24)
        date_str = date.strftime("%d %b %Y at %I:%M %p")
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
           when "ABORTED" then -1.0
           else raise "unexpected result = #{job_json_obj['result']}"
        end

        JenkinsJobStatus.new(job_name, job_json_obj['displayName'], date_str, progress, job_json_obj['url']);
   end
end
