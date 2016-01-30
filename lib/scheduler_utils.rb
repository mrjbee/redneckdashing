module SchedulerUtils

  def SchedulerUtils.smart_schedule (scheduler, title, fallback_time, action)

    # define call and schedule
    _re_scheduler_action = lambda { |next_schedule|
      begin
        # something which might raise an exception
        puts ("[job: #{title}] going to start execution")
        next_schedule_time = action.call
      rescue => error
        # code that deals with some exception
        puts ("[job: #{title}] !!! ERROR during executing. Reason = #{error.message}")
        puts error.backtrace
        next_schedule_time = fallback_time
      ensure
        # ensure that this code always runs, no matter what
        puts ("[job: #{title}] next execution in #{next_schedule_time}")
        scheduler.in next_schedule_time+ rand(5), next_schedule
      end
    }

    #start recursive hell
    scheduler.in 0 do
      _re_scheduler_action.call(_re_scheduler_action)
    end
  end

end