class Dashing.Text extends Dashing.Widget

  @accessor 'broken_job_visible', ->
    if @get('brokenJobsCount') == 0
      "not-visible"
    else
      "visible"
