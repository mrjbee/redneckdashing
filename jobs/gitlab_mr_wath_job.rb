require_relative '../lib/gitlab.rb'
require_relative '../lib/setup.rb'
require_relative '../lib/scheduler_utils'


Setup.gitLab_open_MR.each do |title, details|

  project_index = 0

  SchedulerUtils.smart_schedule SCHEDULER, title, 60, lambda {
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

    send_event( title,   {
        projectName: project_name,
        projectUrl: gerrit_project.web_url,
        mrs: open_requests
    })

    (mrs.size==0?1:mrs.size) * details[:update_per_mr_seconds]
  }

end
