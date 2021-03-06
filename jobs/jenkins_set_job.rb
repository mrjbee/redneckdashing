require_relative '../lib/jenkins.rb'
require_relative '../lib/setup.rb'

Setup.jenkins_job_sets.each do |title, jobset|

  SchedulerUtils.smart_schedule SCHEDULER, title, 300, lambda {

    job_statuses =jobset[:jobs].map { |jobTitle|
      Jenkins.lastJobStatus(jobset[:server], jobTitle)
    }

    running_job = job_statuses.find{|job| job.is_in_progress}
    if running_job
      send_event( title,   {
          jobNameVal: running_job.job_full_name,
          startAtVal: running_job.start_at,
          urlVal: running_job.url,
          healthStateVal: 0})
    else
      failed_job = job_statuses.find{|job| job.is_fail}
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

    jobset[:update]
  }

end
