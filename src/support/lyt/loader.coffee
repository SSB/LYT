# Requires `/common`  
# Requires `/support/jqm/jqm.extensions`  
# Requires `i18n`  

# -------------------

# This module keeps track of who is trying to load what and animates the interface appropriately

LYT.loader = do ->
  
  # ## Privileged API
    
  loaders = []
  defaultMessage = "Loading"
  
  lockPage = ->
    jQuery(".ui-page-active").fadeTo(500, 0.4)
    #todo: implement interface locking
    #$('document').click (event) ->
    #  log.message "someone tried to click something whle we are loading"
    #  event.preventDefault()
    #  event.preventDefaultPropagation()
  
  unlockPage = ->
    jQuery(".ui-page-active").fadeTo(500, 1)
  
  # ## Public API
  
  # Register a Promise. When the Promise finishes,
  # it'll close its loading message.  
  # There are 2 ways to call this method:
  # 
  #     LYT.loader.register promiseObj
  # 
  # which uses the default message, or:
  # 
  #     LYT.loader.register message, promiseObj
  register: (message, promise) ->
    [message, promise] = [defaultMessage, promise] if arguments.length is 1
    return unless promise.state() is "pending"
    @set message, promise, false
    promise.always => @close promise
  
  # Set a custom loading message
  set: (message, id, clearStack = true) ->
    # register new loader with ID, if clearStack is true close all previous loaders
    jQuery.mobile.showPageLoadingMsg LYT.i18n(message)
    
    lockPage()   if loaders.length is 0
    loaders = [] if clearStack
    
    loaders.push id
  
  # Close a loading message
  close: (id) ->
    # close loader with id and unlock interface if all loaders are closed
    loaders.splice index, 1 while (index = loaders.indexOf id) isnt -1
    
    if loaders.length is 0
      jQuery.mobile.hidePageLoadingMsg()
      unlockPage()
  
  # Clear the loading stack
  clear: ->
    loaders = []
    jQuery.mobile.hidePageLoadingMsg()
    unlockPage()
  

