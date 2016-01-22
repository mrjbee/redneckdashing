require_relative '../lib/jenkins.rb'

job_mapping = {
  'taskservice' => {
    :server => 'https://ci.jenkins-ci.org',
    :title => 'infra_backend-war-size-tracker',
    :update => '5s'
  },
  'upstream' => {
    :server => 'https://builds.apache.org',
    :title => 'Hadoop-ATS-v2',
    :update => '30s'
  }
}

job_mapping.each do |title, job|

  last_job_health_state = -100

  SCHEDULER.every job[:update], :first_in => rand(5)  do
    current_job_details = Jenkins.lastJobStatus(job[:server], job[:title])
    puts "Just fetched job = #{current_job_details}"
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
