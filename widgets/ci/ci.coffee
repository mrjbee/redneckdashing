class Dashing.Ci extends Dashing.Widget

  @accessor 'value', Dashing.AnimatedValue


  @accessor 'startAtVal', ->
    "Started at #{@get('startAtValue')}"

  constructor: ->
    super
    @observe 'value', (value) ->
      $(@node).find(".ci").val(value).trigger('change')

  ready: ->
    ci = $(@node).find(".ci")
    ci.attr("data-bgcolor", ci.css("background-color"))
    ci.attr("data-fgcolor", ci.css("color"))
    ci.knob()

  onData: (data) ->
    console.log(data.healthStateValue)
    $(@node).fadeOut =>
      if data.healthStateValue == 0
        $(@node).css('background-color', '#9c4274')
        #when failed
      if data.healthStateValue == -1
        $(@node).css('background-color', '#4b4b4b')
        #when over running
      if data.healthStateValue == -2
        $(@node).css('background-color', '#64334f')
    $(@node).fadeIn()
