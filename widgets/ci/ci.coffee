class Dashing.Ci extends Dashing.Widget

  @accessor 'value', Dashing.AnimatedValue

  constructor: ->
    super
    @observe 'value', (value) ->
      $(@node).find(".ci").val(value).trigger('change')

  ready: ->
    ci = $(@node).find(".ci")
    ci.attr("data-bgcolor", ci.css("background-color"))
    ci.attr("data-fgcolor", ci.css("color"))
    ci.knob()
