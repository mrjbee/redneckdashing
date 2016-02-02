class Dashing.Omr extends Dashing.Widget

  @accessor 'mrsCount', ->
    "#{@get('mrs').length}"

  @accessor 'mrText', ->
    "#{@get('current')?.title}"

  @accessor 'mrCreatedAgo', ->
    "#{@get('current')?.create_date_ago}"

  @accessor 'mrAuthor', ->
    "#{@get('current')?.author_name}"

  @accessor 'mrAuthorAvatar', ->
    "#{@get('current')?.author_avatar}"

  @accessor 'mrAssigneeVisibility', ->
    if @get('current')? && @get('current').assignee_name?
      "visible"
    else
      "not-visible"

  @accessor 'mrAssignee', ->
    "#{@get('current')?.assignee_name}"

  @accessor 'mrAssigneeAvatar', ->
    "#{@get('current')?.assignee_avatar}"

  @accessor 'mrUpdateText', ->
    "“#{@get('current')?.update_text}”"

  @accessor 'mrUpdatedAgo', ->
    "#{@get('current')?.update_date_ago}"

  @accessor 'mrUpdatedAuthor', ->
    "#{@get('current')?.update_author}"

  @accessor 'mrUpdateAvatar', ->
    "#{@get('current')?.update_author_avatar}"


  @accessor 'mrUpdateVisibility', ->
    if @get('current')? && @get('current').update_text?
      "visible"
    else
      "not-visible"

  ready: ->
    @currentIndex = 0
    @commentElem = $(@node).find('.container')
    @nextComment()
    @startCarousel()

  onData: (data) ->
    @currentIndex = 0

  startCarousel: ->
    setInterval(@nextComment, 5000)

  nextComment: =>
    mrs = @get('mrs')
    if mrs.length != 0
      #console.log("[OMR] There are #{mrs.length} items. Fade out for update")
      @commentElem.fadeOut =>
        @currentIndex = (@currentIndex + 1) % mrs.length
        @set 'current', mrs[@currentIndex]
        #console.log("[OMR] Fade in for #{@currentIndex} item which is #{@get 'current'}")
        @commentElem.fadeIn()
    else
      #console.log("[OMR] not items hide view = #{@commentElem}")
      @set 'current', null
      @commentElem.fadeOut =>
        #console.log("[OMR] do nothing")
