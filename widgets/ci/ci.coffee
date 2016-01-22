class Dashing.Ci extends Dashing.Widget

  @accessor 'value', Dashing.AnimatedValue

  @accessor 'startAtVal', ->
    "Started at #{@get('startAtValue')}"

  constructor: ->
    super
    @observe 'value', (value) ->
      $(@node).find(".ci").val(value).trigger('change')

  ready: ->
    $(@node).attr('lastHealthStateValue', 0);
    ci = $(@node).find(".ci")
    ci.attr("data-bgcolor", ci.css("background-color"))
    ci.attr("data-fgcolor", ci.css("color"))
    ci.knob()

  onData: (data) ->
    actualValue = parseInt(data.healthStateValue)
    wasValue = parseInt($(@node).attr('lastHealthStateValue'))
    changedSinceLastTime = (wasValue != actualValue)
    healthStateValue = data.healthStateValue

    $(@node).attr('lastHealthStateValue',healthStateValue);

    if (changedSinceLastTime)
      color = '#9c4274'
        #when failed
      if actualValue == -1
        color = '#4b4b4b'
        #when over running
      if actualValue == -2
        color = '#64334f'

      $(@node).fadeOut =>
        $(@node).css('background-color', color)
      $(@node).fadeIn()
    else
      color = '#9c4274'
        #when failed
      if actualValue == -1
        color = '#4b4b4b'
        #when over running
      if actualValue == -2
        color = '#64334f'

      $(@node).css('background-color', color)
