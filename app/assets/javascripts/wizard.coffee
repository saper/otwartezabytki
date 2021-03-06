#= require sugar
#= require jquery-specializer
#= require gmaps

map = undefined

geocode_location = (callback) ->
  voivodeship = $('form.suggestion').data('voivodeship')
  district = $('form.suggestion').data('district')
  commune = $('form.suggestion').data('commune')
  city = $('#place_name_viewer').val()
  street = $('#suggestion_street').val()

  jQuery.get geocoder_search_path, {voivodeship, district, commune, city, street}, (result) ->
    if result.length > 0
      $('#suggestion_latitude').val(result[0].latitude.round(7))
      $('#suggestion_longitude').val(result[0].longitude.round(7))
      callback(result[0].latitude.round(7), result[0].longitude.round(7)) if callback?
    else
      callback() if callback?

$.fn.specialize

  '.step':

    input: -> this.find("input[type='text']")
    action: -> this.find("#" + this.input().attr('id') + '_action')

    switchViewClass: (klass) ->
      this.saveLocalHistory()
      this.removeClass('step-done step-skipped step-confirmed step-edited step-view step-edit')
      this.addClass(klass)
      $(".help-content").removeClass('active')
      $('.step').removeClass('step-current')
      this.addClass('step-current')
      this.action().val('skip')

    view: ->
      this.switchViewClass('step-view')
      this.find('button.edit').focus()

      this

    edit: ->
      this.switchViewClass('step-edit')
      this.input().edit()

      if this.data('autoscroll')?
        document.location.hash = this.data('autoscroll')

      this

    submit: ->
      if this.hasClass('step-simple') && this.input().val() == ""
        alert("Nie możesz pozostawić pustego pola.")
        return false

      this.switchViewClass('step-view step-done step-edited')
      this.action().val('edit')
      this.input().save()
      this.done()
      this

    confirm: ->
      this.switchViewClass('step-view step-done step-confirmed')
      this.action().val('confirm')
      this.done()
      this

    skip: ->
      this.switchViewClass('step-view step-done step-skipped')
      this.action().val('skip')
      this.done()
      this

    cancel: ->
      this.restoreHistory()
      this.input().save()
      this.view()
      this.saveLocalHistory()
      this

    done: ->
      $('.step').removeClass('step-current')
      this.addClass('step-done').removeClass("step-current")
      next_step = $('.step:not(.step-done):first')
      setHeight = next_step.offset().top - (($(window).height() / 2) - (next_step.height() / 2)) + 100

      setTimeout ->
        $('body').animate scrollTop: setHeight, 400, ->
          next_step.view()
      , 300
      this

    back: ->
      if $('.step-current').input().hasChanged()
        alert('Najpierw musisz skończyć edytować bieżące pole.')
      else
        if $('.step-current').hasClass('step-edit')
          $('.step-current').cancel()

        current_step = $('.step-current')

        if this.hasClass('step-edited') && !this.hasClass('step-current')
          this.edit()
        else
          this.view()

        current_step.restoreLocalHistory()

      this

    saveHistory: ->
      this.input().saveHistory()
      this.action().saveHistory()
      this

    restoreHistory: ->
      this.input().restoreHistory()
      this.action().restoreHistory()
      this

    saveLocalHistory: ->
      this.data('class', this.attr('class'))
      this.input().saveLocalHistory()
      this.action().saveLocalHistory()

    restoreLocalHistory: ->
      this.action().restoreLocalHistory()
      this.input().restoreLocalHistory()
      this.attr('class', this.data('class'))
      this.removeClass('step-current')

    restoreLocalState: ->
      this.input().restoreLocalState()

    hasChanged: ->
      this.input().hasChanged()

  # place step have select field instead of text
  '.step-place':

    input: -> $("#suggestion_place_id")

    edit: ->
      this.switchViewClass('step-edit')
      $('#suggestion_place_id').focus()
      this

    submit: ->
      this.find('#place_name_viewer').val(this.find('#suggestion_place_id option:selected').text())
      this.switchViewClass('step-view step-done step-edited')
      this.action().val('edit')
      this.done()
      geocode_location ->
        $('#map_canvas').auto_zoom()

      this

    cancel: ->
      this.restoreHistory()
      this.input().save()
      this.find('#suggestion_place_id').val(this.input().val())
      this.find('#place_name_viewer').val(this.find('#suggestion_place_id option:selected').text())
      this.view()
      this.saveLocalHistory()
      this

  '.step-street':

    submit: ->
      if this.hasClass('step-simple') && this.input().val() == ""
        alert("Nie możesz pozostawić pustego pola.")
        return false
      this.switchViewClass('step-view step-done step-edited')
      this.action().val('edit')
      this.input().save()
      this.done()
      geocode_location ->
        $('#map_canvas').auto_zoom()
      this

  # place step have select field instead of text
  '.step-tags':

    input: -> this.find("input[type='checkbox']")
    action: -> this.find('#suggestion_tags_action')

    view: ->
      this.switchViewClass('step-view')
      this

    skip: ->
      this.cancel()
      this.find('.tag-names:first').val("nie wybrano żadnych określeń")
      this.switchViewClass('step-view step-done step-skipped')
      this.action().val('skip')
      this.done()
      this


  '.step-gps':

    input: -> $('#suggestion_latitude, #suggestion_longitude')
    action: -> $('#suggestion_coordinates_action')

    view: ->
      this.switchViewClass('step-view')
      $('#map_canvas').resizeNicely()
      if $('section.subrelics').length && not jQuery.cookie('gps-instructions')
        this.find('.help').click()
        jQuery.cookie('gps-instructions', true)

      this

    edit: ->
      this.switchViewClass('step-edit')
      $('#map_canvas').resizeNicely()

      this

    cancel: ->
      map.removeMarkers()
      this.restoreHistory()
      this.input().save()
      this.view()
      this.saveLocalHistory()
      this.removeClass('step-editing')

      setTimeout ->
        $('#map_canvas').auto_zoom();
      , 1000
      this

    skip: ->
      this.cancel()
      this.switchViewClass('step-view step-done step-skipped')
      this.action().val('skip')
      this.done()
      this

    done: ->
      $('.step').removeClass('step-current')
      this.addClass('step-done').removeClass("step-current")
      next_step = $('.step:not(.step-done):first')
      setHeight = next_step.offset().top - (($(window).height() / 2) - (next_step.height() / 2)) + 100

      setTimeout ->
        $('html,body').animate scrollTop: setHeight, 400, ->
          next_step.view()
          $('#map_canvas').resizeNicely()
      , 300
      this


  'input, select':

    edit: ->
      this.prop('readonly', false)
      this.prop('placeholder', '')
      this.focus().val(this.val())
      this

    save: ->
      this.prop('readonly', true)
      this.prop('placeholder', 'Brak danych')
      this.blur().trigger('liszt:updated')
      this

    saveHistory: ->
      this.each ->
        $(this).data('history', $(this).val())
      this

    restoreHistory: ->
      this.each ->
        if $(this).data('history') != undefined
          $(this).val($(this).data('history'))
      this

    saveLocalHistory: ->
      this.each ->
        $(this).data('local_history', $(this).val())
      this

    restoreLocalHistory: ->
      this.each ->
        $(this).val($(this).data('local_history'))
      this

    hasChanged: ->
      this.toArray().some (e) ->
        $(e).data('local_history') != $(e).val()


  'input[type="checkbox"]':

    edit: ->
      this

    save: ->
      this

    saveHistory: ->
      this.each ->
        $(this).data('history', $(this).prop('checked'))

      this

    restoreHistory: ->
      this.each ->
        $(this).prop('checked', $(this).data('history'))

      this

    saveLocalHistory: ->
      this.each ->
        $(this).data('local_history', $(this).prop('checked'))

      this

    restoreLocalHistory: ->
      this.each ->
        $(this).prop('checked', $(this).data('local_history'))
      this

    hasChanged: ->
      this.toArray().some (e) ->
        $(e).data('local_history') !=  $(e).prop('checked')

  '#suggestion_latitude, #suggestion_longitude':
    edit: ->
    save: ->

  '#map_canvas':

    map: -> map

    zoom_at: (lat, lng) ->
      if map?
        map.setCenter(lat, lng)
      else
        map = new GMaps
          div: '#map_canvas'
          width: 900
          height: 500
          zoom: 17
          lat: lat
          lng: lng
          mapTypeId: google.maps.MapTypeId.HYBRID

    auto_zoom: ->
      latitude = $('#suggestion_latitude').val().toNumber()
      longitude = $('#suggestion_longitude').val().toNumber()
      this.zoom_at(latitude, longitude)
      map.removeMarkers()
      this.circle_marker()

    circle_marker: ->
      latitude = $('#suggestion_latitude').val().toNumber()
      longitude = $('#suggestion_longitude').val().toNumber()
      map.addMarker
        lat: latitude
        lng: longitude
        icon: new google.maps.MarkerImage(small_marker_image_path, null, null, new google.maps.Point(8, 8))

    set_marker: (lat, lng) ->
      map.removeMarkers()

      marker = map.addMarker
        lat: lat
        lng: lng
        draggable: true
        dragend: (e) ->
          new_lat = marker.getPosition().lat().round(7)
          new_lng = marker.getPosition().lng().round(7)
          $('#suggestion_latitude').val(new_lat)
          $('#suggestion_longitude').val(new_lng)
          $('#map_canvas').zoom_at(new_lat, new_lng)

        $('#suggestion_latitude').val(lat.round(7))
        $('#suggestion_longitude').val(lng.round(7))

      $('#map_canvas').zoom_at(lat, lng)

    resizeNicely: ->
      setTimeout ->
        google.maps.event.trigger(map.map, 'resize')
        setTimeout ->
          $('#map_canvas').zoom_at($('#suggestion_latitude').val(), $('#suggestion_longitude').val())
        , 500
      , 500
      this

    blinking: ->
      if !this.parents('.step').hasClass('step-editing') && this.parents('.step').hasClass('step-current')
        map.counter ||= 1
        map.counter += 1
        if map.counter % 2 || this.parents('.step').hasClass('step-edit')
          this.circle_marker() if map.markers.length == 0
        else
          map.removeMarkers()

      setTimeout ->
        $('#map_canvas').blinking()
      , 1000

jQuery ->

  window.bypass_submit = false

  return unless $('body').hasClass('relics') && $('body').hasClass('edit')

  # prevent form submission until end of the wizard
  $('form.suggestion').submit (e) ->
    $('.step-submit').addClass('step-done')
    if !window.bypass_submit && $('.step:not(.step-done)').length > 0
      $('.step:not(.step-done):first').view()
      false
    else
      $('.steps input[disabled]').prop("disabled", false)
      window.bypass_submit = true

  # turn of autocompletion for all inputs
  $('.step input[type="text"]').attr('autocomplete', 'off')

  $('.step').on 'click', '.action-back a', ->
    $(this).parents('.step:first').back()
    return false

  # register actions for wizard
  ['edit', 'skip', 'confirm'].forEach (action) ->
    $('.step-simple,.step-gps').on 'click', ".action-#{action} a" , ->
      step_div = $(this).parents('.step:first')

      if !step_div.hasClass('step-edit') && step_div.hasClass('step-current')
        step_div[action]()

      return false # prevent the form submission

  ['submit', 'cancel'].forEach (action) ->
    $('.step-simple, .step-gps').on 'click', ".action-#{action} a" , ->
      step_div = $(this).parents('.step:first')

      if step_div.hasClass('step-current')
        step_div[action]()

      return false # prevent the form submission

  $('.step-tags').on 'click', ".action-submit a" , ->
    step_div = $(this).parents('.step:first')
    if step_div.hasClass('step-current') && step_div.hasClass('step-edit')
      step_div.submit()

    return false # prevent the form submission

  $('.step-tags').on 'click', ".action-skip a" , ->
    step_div = $(this).parents('.step:first')
    if step_div.hasClass('step-current')
      $(this).parents('.step:first').skip()

    return false

  $('.step-gps').on 'click', ".action-skip a" , ->
    step_div = $(this).parents('.step:first')
    if step_div.hasClass('step-current')
      $(this).parents('.step:first').skip()

    return false # prevent the form submission

  $('.step-simple').on 'keyup', 'input[type="text"]', (e) ->
    stroke = if (_ref = e.which) != null then _ref else e.keyCode
    $(this).parents('.step:first').submit() if stroke == 13

  $('.step-tags input[type="checkbox"]').change ->
    step = $(this).parents('.step')
    if step.find('input[type="checkbox"]:checked').length > 0
      step.edit() if step.hasClass('step-view')
    else
      step.view() if step.hasClass('step-edit')

    tags = step.find('input[type="checkbox"]:checked').toArray().map (e) ->
      $(e).parents('label:first').find('span').text()

    if tags.length > 0
      step.find('.tag-names:first').val(tags.join(', '))
    else
      step.find('.tag-names:first').val("nie wybrano żadnych określeń")


  $('.step').each -> $(this).saveHistory()

  $(".steps").on "click", ".help-content .help, .help-extended .close", ->
    if $(this).parents('.step').hasClass('step-current')
      $(this).parents(".help-content").toggleClass('active')

    false

  suggeston_place = $('#suggestion_place_id').css(width: 300)[0]
  suggeston_choosen = new Chosen(suggeston_place, no_results_text: '<a href="#" class="add_place_button">Dodaj</a>')
  add_suggestion_callback = (e) ->
    new_name = $('#suggestion_place_id_input .chzn-search input').val()
    if $('#suggestion_place_id_input .no-results').length > 0 && new_name.length > 0 && confirm('Czy na pewno chcesz dodać nową miejscowość w tej gminie?')
      $('#suggestion_place_id option[data-type="optional"]').remove()
      $('#suggestion_place_id').append($("<option data-type='optional' value='#{new_name}'>#{new_name}</option>"))
      $('#suggestion_place_id').val("#{new_name}")
      $('#suggestion_place_id').trigger('liszt:updated')

    suggeston_choosen.close_field(e)
    false

  $('#suggestion_place_id_input').on('click', '.add_place_button', add_suggestion_callback)
  $('#suggestion_place_id_input').on 'keyup', ' .chzn-search input', (e) ->
    stroke = if (_ref = e.which) != null then _ref else e.keyCode
    add_suggestion_callback(e) if stroke == 13

  $('#go_to_next').click ->
    window.bypass_submit = true
    $('#new_suggestion').submit()
    return false


  # type class of step in browser hash to debug
  if window.location.hash.match(/step/)
    $(".#{window.location.hash.slice(1)}:first").view()

  $('a.colorbox').colorbox({rel: "gal"})

  wizard_spinner_opts =
    lines: 13
    length: 30
    width: 20
    radius: 100
    rotate: 0
    color: '#aaa'
    speed: 0.2
    trail: 74
    shadow: true
    hwaccel: false
    className: 'spinner'
    zIndex: 2e9
    top: 100
    left: 'auto'


  spinner = new Spinner(wizard_spinner_opts).spin($('.overlay')[0])

window.google_maps_loaded = ->
  jQuery ->
    window.loadGMaps();

    $('#marker').draggable
      revert: true

    $('#map_canvas').droppable
      drop: (event, ui) ->

        x_offset = (ui.offset.left - $(this).offset().left + 39)
        y_offset = (ui.offset.top - $(this).offset().top + 55)

        lng = map.map.getBounds().getSouthWest().lng()
        lat = map.map.getBounds().getNorthEast().lat()
        width = map.map.getBounds().getNorthEast().lng() - map.map.getBounds().getSouthWest().lng()
        height = map.map.getBounds().getSouthWest().lat() - map.map.getBounds().getNorthEast().lat()
        marker_lat = lat + height * y_offset / $(this).height()
        marker_lng = lng + width * x_offset / $(this).width()
        $('#map_canvas').set_marker(marker_lat, marker_lng)
        $(this).parents('.step').addClass('step-editing')

    $('#map_canvas').auto_zoom()
    $('#map_canvas').blinking()

# for animations
$(window).load ->
  $('body').addClass('loaded')

  window.onbeforeunload = ->
    return null if window.bypass_submit
    if $('.step-edited').length > 0 || $('.step-confirmed').length > 0 || $('.step-edit').length > 0
      return 'Jeśli wyjdziesz z tej strony, wprowadzone zmiany będą stracone.'

  $('head').append($($('#after_load_css').html()))
