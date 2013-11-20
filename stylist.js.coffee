window.stylist =

  reloadStylesheets: (stylesheet)->
    # query string to append to link's href 
    queryString = "?reload=" + new Date().getTime()
    if stylesheet and stylesheet != 'auto'
      # reloading a specific stylesheet only
      link = $("link[href*=#{stylesheet}]")
      link.attr('href', link.attr('href').replace(/\?.*$/, queryString)) if link and link.attr('href')
    else
      # reload all stylesheets  
      $("link[rel=\"stylesheet\"]").each ->
        @href = @href.replace(/\?.*|$/, queryString) if @href.match window.location.hostname
    # reload html 
    $('body').html($('body').html())
    document.body.onclick = ->
      $('body').html($('body').html())
      document.body.onclick = null

  sendRequest: (mode, data)->
    params = {}
    names = ["selector", "attribute", "value"]
    for item in data
      params[names[_i]] = item
    if stylist.stylesheet
      params["stylesheet"] = stylist.stylesheet
    else
      params["stylesheet"] = "auto"
    $.ajax  
      url:        "#{window.location.protocol}//#{window.location.host}/stylist/#{params['stylesheet']}"
      type:       mode
      dataType:   "json"
      data:       params
      success:    (r)-> console.log(r); return
      error:      (r)->
        console.log r
        window.stylist.html = $('body').html()
        $('body').html(r.responseText)
        document.body.ondblclick = ->
          $('body').html(window.stylist.html)
          document.body.ondblclick = null
      complete:   (r)-> window.stylist.reloadStylesheets(params["stylesheet"]) if mode in ['PUT', 'DELETE']
    return 

  set: ->
    if arguments.length > 1 and typeof arguments[1] is "object"
      window.stylist.set_obj(arguments[0], arguments[1])
    else
      window.stylist.sendRequest "PUT", arguments

  get: ->
    window.stylist.sendRequest "GET", arguments

  rm: ->
    window.stylist.sendRequest "DELETE", arguments

  set_obj: (selector, obj)->
    for k,v of obj
      window.stylist.sendRequest "PUT", [selector, k, v]
  
  setget: ->
    if arguments.length < 3
      window.stylist.get.apply(this, arguments)
    else
      window.stylist.set.apply(this, arguments)
        
      
