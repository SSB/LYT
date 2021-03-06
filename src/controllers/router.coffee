# Requires `/common`  
# Requires `control`  
# Requires `player`  
# Requires `/view/render`  

# -------------------

# This module serves as a router to the rest of the application and contains url entrypoints and event listeners


#     bc  => pagebeforecreate
#     c   => pagecreate
#     i   => pageinit
#     bs  => pagebeforeshow
#     s   => pageshow
#     bh  => pagebeforehide
#     h   => pagehide
#     rm  => pageremove

# -------------------

LYT.var =
  next: null # store nextpage 
  searchTerm: null # store last search term
  callback: null #last callback function

$(document).ready ->
  LYT.player.init() if not LYT.player.ready
  LYT.render.init()

$(document).bind "mobileinit", ->
  LYT.router = new $.mobile.Router([
    "#book-details([?].*)?":
      handler: "bookDetails"
      events: "s,bs" #
    "#book-play([?].*)?":
      handler: "bookPlayer"
      events: "s"
    "#book-index([?].*)?":
      handler: "bookIndex"
      events: "s"
    "#settings":
      handler: "settings"
      events: "s"
    "#support":
      handler: "support"
      events: "s"
    "#about":
      handler: "about"
      events: "s"
    "#share":
      handler: "share"
      events: "s"
    "#search([?].*)?":
      handler: "search"
      events: "s"
    "#login":
      handler: "login"
      events: "s"
    "#profile":
      handler: "profile"
      events: "s"
    "#bookshelf":
      handler: "bookshelf"
      events: "s"
    "#anbefalinger":
      handler: "anbefal"
      events: "bc"


   ], LYT.control, { ajaxApp: false }) #defaultHandler: 'bookDetails'
 
 
 #logon rejected from  LYT.service....  
  $(LYT.service).bind "logon:rejected", () ->
    LYT.var.next = window.location.hash #if window.location.hash is "" you came from root
    unless LYT.var.next is "#login" 
      $.mobile.changePage "#login"   

  $(LYT.service).bind "logoff", ->
    LYT.player.clear()
    
    $.mobile.changePage "#login"

 #logon rejected from  LYT.session....  
  $(LYT.session).bind "logon:rejected", () ->
    LYT.var.next = window.location.hash #if window.location.hash is "" you came from root
    unless LYT.var.next is "#login" 
      $.mobile.changePage "#login"   


#logon rejected from  LYT.catalog....

  $(LYT.catalog).bind "logon:rejected", () ->
    LYT.var.next = window.location.hash #if window.location.hash is "" you came from root
    unless LYT.var.next is "#login" 
      $.mobile.changePage "#login"
        
  $("[data-role=page]").live "pageshow", (event, ui) ->
    _gaq.push [ "_trackPageview", event.target.id ]

#Lyt service error handling (events)    
  
  $(LYT.service).bind "error:rpc", () ->
    #alert "Der er opstået et netværksproblem, prøv at genindlæse siden"
    #todo: apologize on behalf of the server
  $(LYT.service).bind "error:service", () ->
    #alert "Der er opstået et netværksproblem, prøv at genindlæse siden"
  
