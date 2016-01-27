class Dashing.Cicartoon extends Dashing.Widget

  @accessor 'imageResolution', ->
      switch(@get('healthStateVal'))
        when -1 then "assets/bart.png"
        when 0 then "assets/homer.gif"
        when 1 then "assets/marge.png"

  @accessor 'resolution', ->
      switch(@get('healthStateVal'))
        when -1 then "Some stupid Bart just kill our CI... well at least following job"
        when 0 then "Homer is thinking... well at least he think so... about following job"
        when 1 then "Now it's Marge's time to shine! Everything is working."
