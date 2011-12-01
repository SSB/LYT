# This module serves as a router to the rest of the application and contains url entrypoints and event listeners

$(document).ready ->
  if not LYT.player.ready
    LYT.player.setup()

$(document).bind "mobileinit", ->
    
  LYT.router = new $.mobile.Router([
    "#book-details([?].*)?":
      handler: "bookDetails"
      events: "bs"
    "#book-play([?].*)?":
      handler: "bookPlay"
      events: "bs"
    "#book-index([?].*)?":
      handler: "bookIndex"
      events: "bs"
    "#settings":
      handler: "settings"
      events: "bs"
    "#search([?].*)?":
      handler: "bookDetails"
      events: "bs"
    "#login":
      handler: "login"
      events: "bs"
    "#logout":
      handler: "logout"
      events: "bs"
    "#bookshelf":
      handler: "bookshelf"
      events: "bs"
    
   ], LYT.control, { ajaxApp: false })
  
  
  $(LYT.service).bind "logon:rejected", () ->
    $.mobile.changePage "#login"
  
  $(LYT.service).bind "error:rpc", () ->
    #todo: apologize on behalf of the server 
  
  ###
  $(document).bind "pagebeforechange", (e, data) ->
      # Intercept and parse urls with a query string
      # As done here http://jquerymobile.com/test/docs/pages/page-dynamic.html
      if typeof data.toPage is "string"
        u = $.mobile.path.parseUrl(data.toPage)
        if (/^#book-details/i).test u.hash
          LYT.app.bookDetails u, data.options
          e.preventDefault()
        else if (/^#book-play/i).test u.hash
          LYT.app.bookPlayer u, data.options
          e.preventDefault()
        else if (/^#book-index/i).test u.hash
          log.message "Main: changepage"
          LYT.app.bookIndex u, data.options
          e.preventDefault()
  ###
  ###
  $("#login").live "pagebeforeshow", (event) ->
      $("#login-form").submit (event) ->

        $.mobile.showPageLoadingMsg()
        $("#password").blur()

        LYT.service.logOn($("#username").val(), $("#password").val())
          .done ->
            $.mobile.changePage "#bookshelf"

          .fail ->
            log.message "log on failure"

        event.preventDefault()
        event.stopPropagation()

  $("#bookshelf").live "pagebeforeshow", (event) ->
    LYT.app.bookshelf()
  ###
  ###
  $('#search').live "pagebeforeshow", (event) ->
    # TODO: Move the search logic to a separate file?  
    # Also, shouldn't the `$("#search-form").submit` call only
    # happen once (in either`mobileinit` or `$(document).ready`)?
    # Right now, I'm guessing it happens every time the search page
    # is shown so more and more submit handlers are added... doesn't
    # seem correct...
    $("#search-form").submit ->
      $('#searchterm').blur()
      $.mobile.showPageLoadingMsg()
      $('#searchresult').empty()
      $.ajax
        contentType: "application/json; charset=utf-8",
        dataType:    "json",
        url:         "/CatalogSearch/search.asmx/SearchFreetext",
        type:        "POST"
        data:        JSON.stringify(term: $('#searchterm').val())
        
        # TODO: I think success-handler this should probably be a
        # `renderSearchResults` function in `LYT.gui` or something.
        # If nothing else, there shouldn't be any UI text this file
        success: (data, status) -> 
          # TODO: More robust checking. If `data` or `data.d` or `data.d[0]`
          # don't exist for some reason, this code will fail
          if data.d[0].resultstatus isnt "NORESULTS"
            # TODO: Properly pluralize "resultat". It just looks so lazy
            # to say "resultat(er)". Also, hard-coded UI text here? Oh, noes!
            s = "<li><h3>#{data.d[0].totalcount}resultat(er)</h3></li>"
            for item in data.d
              s += """
               <li id="#{item.imageid}">
                 <a href="#book-details">
                   <img class="ui-li-icon" src="/images/default.png">
                   <h3>#{item.title}</h3>
                   <p>#{item.author}|#{LYT.gui.parseMediaType item.media}</p>
                 </a>
               </li>"""
          else
            s += '<li><h3>Ingen resultater</h3></li>'
          $('#searchresult').html(s)
        error: onSearchError
        complete: onSearchComplete

    onSearchError = (msg, data)->
      $("#searchresult").text("Error thrown: " + msg.status);

    onSearchComplete = ->
      $('#searchresult').listview('refresh');
      $('#searchresult').find('a:first').css 'padding-left','40px'
      $.mobile.hidePageLoadingMsg();
      LYT.gui.covercache($('#searchresult').html())
        
    $("#searchterm").autocomplete
      minLength: 2
      source: (request, response) ->
        # TODO: OH SHI---! Duplication of ajax options... D.R.Y! :)
        # Also, move it to `config` 
        $.ajax
          url:         "/CatalogSearch/search.asmx/SearchAutocomplete"
          data:        JSON.stringify(term: $('#searchterm').val())
          dataType:    "json"
          type:        "POST"
          contentType: "application/json; charset=utf-8"
          
          # TODO: Is the `dataFilter` even necessary? It's just an identity function...
          dataFilter: (data) -> data
          
          success: (data) ->
            response($.map(data.d, (item)-> value: item.keywords))
            list = $('.ui-autocomplete').find('li').each ->
              item = jQuery this
              item.removeAttr 'class'  
              item.attr 'class', 'ui-icon-searchfield'
              item.removeAttr 'role'
              item.html "<h3>#{item.find('a').text()}</h3>"
              if list.length is 1 and $(list).find('h3:first').text().length is 0
                $(list).html '<h3>Ingen forslag</h3>'
              $('#searchresult').html(list).listview('refresh')
          
          error: (XMLHttpRequest, textStatus, errorThrown) ->
            log.message textStatus
    
    $("#searchresult li").live "click", (event) -> $("#searchterm").val($(this).text())
    
    $("#searchterm").live "autocompleteclose", (event, ui) -> 
      $("#search-form").submit()
    
  $("#settings").live "pagebeforecreate", (event) ->
        initialize = true
        $("#textarea-example").css "font-size",  LYT.settings.get('textSize') + "px"
        $("#textsize").find("input").val LYT.settings.get('textSize')
        $("#textsize_2").find("input").each ->
            $(this).attr "checked", true  if $(this).attr("value") is LYT.settings.get('textSize')

        $("#text-types").find("input").each ->
            $(this).attr "checked", true  if $(this).attr("value") is LYT.settings.get('textType')

        $("#textarea-example").css "font-family", LYT.settings.get('textType')
        $("#marking-color").find("input").each ->
            $(this).attr "checked", true  if $(this).attr("value") is LYT.settings.get('markingColor')

        $("#textarea-example").css "background", LYT.settings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0))
        $("#textarea-example").css "color", LYT.settings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0) + 1)
        $("#textsize_2 input").change ->
            LYT.settings.set('textSize', $(this).attr("value"))

            $("#textarea-example").css "font-size", LYT.settings.get('textSize') + "px"
            $("#book-text-content").css "font-size", LYT.settings.get('textSize') + "px"

        $("#text-types input").change ->
            LYT.settings.set('textType', $(this).attr("value"))

            $("#textarea-example").css "font-family", LYT.settings.get('textType')
            $("#book-text-content").css "font-family", LYT.settings.get('textType')

        $("#marking-color input").change ->
            LYT.settings.set('markingColor', $(this).attr("value"))

            $("#textarea-example").css "background", LYT.settings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0))
            $("#textarea-example").css "color", LYT.settings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0) + 1)
            $("#book-text-content").css "background", vsettings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0))
            $("#book-text-content").css "color", LYT.settings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0) + 1)
  ###
  
  $("[data-role=page]").live "pageshow", (event, ui) ->
        _gaq.push [ "_trackPageview", event.target.id ]