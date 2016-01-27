require_relative '../lib/jenkins.rb'
require_relative '../lib/setup.rb'

Setup.jenkins_job_sets.each do |title, jobset|

  SCHEDULER.every jobset[:update], :first_in => rand(15)  do

    job_statuses =jobset[:jobs].map { |jobTitle|
      Jenkins.lastJobStatus(jobset[:server], jobTitle)
    }

    running_job = job_statuses.detect{|job| job.is_in_progress}
    if running_job
      send_event( title,   {
        jobNameVal: running_job.job_full_name,
        startAtVal: running_job.start_at,
        urlVal: running_job.url,
        healthStateVal: 0})
    else
      failed_job = job_statuses.detect{|job| job.is_fail}
      if failed_job
        send_event( title,   {
          jobNameVal: failed_job.job_full_name,
          startAtVal: failed_job.start_at,
          urlVal: failed_job.url,
          healthStateVal: -1})
      else
        send_event( title,   {
          jobNameVal: "",
          startAtVal: "",
          urlVal: "",
          healthStateVal: 1})
      end
    end

  end
end
