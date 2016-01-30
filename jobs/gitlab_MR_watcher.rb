require_relative '../lib/gitlab.rb'
require_relative '../lib/setup.rb'


Setup.gitLab_open_MR.each do |title, details|

  project_index = 0

  _action = lambda {
    project_index = details[:projects].size > project_index ? project_index:0
    gerrit_project = Gitlab.project(details[:projects][project_index], details[:server], details[:user])
    project_index += 1
    mrs = gerrit_project.open_merge_requests

    project_name = gerrit_project.name
    open_requests = mrs.map{|mr|
        {
            title: mr.title,
            author_name: mr.author.name,
            author_avatar: mr.author.avatar_url,
            create_date_ago: Gitlab.date_iso_8601_to_ago_date(mr.created_at),
            assignee_name: (mr.assignee.name if mr.assignee),
            assignee_avatar: (mr.assignee.avatar_url if mr.assignee),
            update_text: (mr.latest_comment.body if mr.latest_comment),
            update_author: (mr.latest_comment.author.name if mr.latest_comment),
            update_date_ago: (Gitlab.date_iso_8601_to_ago_date(mr.latest_comment.created_at) if mr.latest_comment),
            update_author_avatar: (mr.latest_comment.author.avatar_url if mr.latest_comment)
        }
    }
    puts "[Event] name = #{project_name} MRs = #{open_requests}"
    send_event( title,   {
        projectName: project_name,
        mrs: open_requests
    })

    (mrs.size==0?1:mrs.size) * details[:update_per_mr_seconds]
  }


  # define call and schedule
  _re_scheduler_action = lambda { |next_schedule|
      begin
        # something which might raise an exception
        puts ('Start executing')
        next_schedule_time = _action.call
      rescue => error
        # code that deals with some exception
        puts ("!!! ERROR during executing: #{error.message}")
        puts error.backtrace
        next_schedule_time = 60
      ensure
        # ensure that this code always runs, no matter what
        puts ("Requested next in #{next_schedule_time} sec for #{self}")
        SCHEDULER.in next_schedule_time, next_schedule
      end
  }

  #call recursive if everything is fine
  _re_scheduler_action.call _re_scheduler_action

end
