require_relative '../lib/jenkins.rb'
require_relative '../lib/setup.rb'

Setup.jenkins_jobs.each do |title, job|

  last_job_health_state = -100

  SCHEDULER.every job[:update], :first_in => rand(15)  do
    current_job_details = Jenkins.lastJobStatus(job[:server], job[:title])
    #puts "[#{Time.now.strftime("%d/%m/%Y %H:%M")}] Just fetched job = #{current_job_details}"
    state = 0

    if current_job_details.is_fail
      state = -1
    end

    if current_job_details.is_over_time
      state = -2
    end

    send_event( title,   {
      value: current_job_details.progress_human,
      startAtValue: current_job_details.start_at,
      urlValue: current_job_details.url,
      healthStateValue: state,
      healthStateChangedValue: last_job_health_state != state })
    last_job_health_state = state
  end
end
