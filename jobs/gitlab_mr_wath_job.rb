require_relative '../lib/gitlab.rb'
require_relative '../lib/setup.rb'
require_relative '../lib/scheduler_utils'
require_relative '../lib/utils'
require_relative '../lib/audit'

PROJECT_CACHE = Utils::synchronized_hash

Setup.gitLab_open_MR.each do |title, details|

  project_to_cache_index = 0

  SchedulerUtils.smart_schedule SCHEDULER, title+'_cahce_update', 60, lambda {
    project_id = details[:projects][project_to_cache_index]
    Audit::trace title+'_cahce_update', "Update cache for #{project_id}"
    project = Gitlab.project(project_id, details[:server], details[:user])
    PROJECT_CACHE.put project_id, project

    project_to_cache_index += 1
    project_to_cache_index = details[:projects].size > project_to_cache_index ? project_to_cache_index:0
    project_id = details[:projects][project_to_cache_index]

    return 5 if PROJECT_CACHE.get(project_id) == nil
    Utils.safe details[:delay_fetch_per_project_sec], 120
  }

  project_index = 0

  SchedulerUtils.smart_schedule SCHEDULER, title, 60, lambda {
    project_index = details[:projects].size > project_index ? project_index:0
    project_id = details[:projects][project_index]
    gerrit_project = PROJECT_CACHE.get project_id
    #wait for 5 seconds before cache update
    return 5 if gerrit_project == nil

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

    (mrs.size==0?1:mrs.size) * (Utils.safe details[:delay_update_ui_per_mr_sec], 10)
  }

end
