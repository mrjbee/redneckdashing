require_relative '../lib/gitlab.rb'
require_relative '../lib/setup.rb'
require_relative '../lib/scheduler_utils'
require_relative '../lib/audit'


SchedulerUtils.smart_schedule SCHEDULER, 'welcome', 60, lambda {

  send_event( 'welcome',   {
      brokenJobsCount:Audit::down_components.size
  })

  10
}
