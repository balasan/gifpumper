"use strict"

# Directives 
app = angular.module("gifpumper")





app.directive "randColor", ()->
  link:(scope,el,att)->
    bgcolorlist = new Array("rgba(0,72,234,1)", "rgba(96,0,234,1)", "rgba(114,34,0,1)", "rgba(102,129,135,1)", "rgba(102,204,255,1)", "rgba(252,255,0,1)", "rgba(194,127,255,1)", "rgba(0,95,21,1)", "rgba(255,0,170,1)", "rgba(249,6,6,1)", "rgba(173,216,230,1)", "rgba(40,40,40,1)", "rgba(40,40,40,1)")
    r = Math.random()
    color = bgcolorlist[Math.floor(r * bgcolorlist.length)]
    el.css 
      background: color 


app.directive "notify", ($timeout) ->
  link:(scope,el,att)->
    notify = angular.element(document.getElementById('notifyBox'))
    el.css
      'margin-left': - el[0].offsetWidth+notify[0].offsetWidth+'px'

app.directive "bgImage", ($timeout) ->
  link:(scope,el,att)->
    el.css
      backgroundImage: 'url('+att.bg+')'

# app.directive 'timeago', ($timeout)->
#   link:(scope,el,att)->
#     $timeout ()->
#       # if(att.date!="")
#       #   date = moment(att.date).fromNow();
#       # else
#       #   date = "a while ago"
#       el.html(att.date)



# PAGE
app.directive "subMenu", ($timeout) ->
  link:(scope,el,att)->
    el.css
      left : el.parent()[0].offsetLeft


app.directive "chatbox", ($timeout) ->
  link:(scope,el,att)->
    scope.toBottom = ()->
      el[0].scrollTop = el[0].scrollHeight;
    scope.$watch 'pageData.text.length', ()->
      scope.toBottom;


app.directive "element", ($document, $rootScope, $timeout) ->
  # transclude:true
  # scope: 
  #   el : "="
  #   index: "="
  #   selected: '='
  #   keys: '='
  #   mt: '=' 
  link:(scope, el, att) ->
    startX = startY =  elWidth = elHeight = elX =  elY =  elZ = 0;
    angleX = angleY = angleZ = 0;
    scope.index = scope.$index;
    updateTimer = null;
    okToUpdate = false;

    okToDeselect = false;


    mouseDownHandler = (e) ->
      if e.ctrlKey || e.button > 1
        return;

      if(!$rootScope.selected)
        okToDeselect = false;
      $rootScope.selected = scope.el._id

      elWidth = el[0].offsetWidth 
      elHeight = el[0].offsetHeight
      elX = parseInt(scope.el.left); elY = parseInt(scope.el.top); elZ = scope.el.z
      angleX = scope.el.anglex; angleY = scope.el.angley; angleZ = scope.el.angler

      startX = e.pageX; 
      startY = e.pageY;

      if scope.el.d2d
          startXT = startX
          startZT = 0

      $document.on('mousemove', mousemove);
      $document.on('mouseup', mouseupHandler);
      # $document.on('mouseout', mouseupHandler);
      # el.on('mousedown', deselect)
      # if($rootScope.selected !=null)
      $document.unbind('mouseup', deselect)
      $document.on('mouseup', deselect)

      $timeout( ()->
        okToDeselect = true;
        return null
      ,100);

      scope.$apply();

      # $document.on 'mouseup', ()->
      #   deselect()

    el.on 'mousedown', mouseDownHandler


    deselect = (e) ->
      if okToDeselect && $rootScope.selected == scope.el._id
        $rootScope.selected = null
        # $document.unbind "mousedown", deselect
        scope.$apply()
        $document.unbind('mouseup', deselect)
      okToDeselect = true;

    
      

    mousemove = (e) ->
      x = e.pageX - startX
      y = e.pageY - startY

      if(!updateTimer)
        startTimer()

      $rootScope.selected = scope.el._id

      if scope.el.contentType == "image"
        e.preventDefault();
      # okToDeselect = false;

      # $document.unbind "mousedown", deselect

      # if scope.el.contentType == "image"
      # e.preventDefault();

      if e.shiftKey || scope.transform == 'resize'
        scope.el.width = x + elWidth + 'px'
        scope.el.height = y + elHeight + 'px'
      else if (e.altKey || scope.transform == 'z') && !scope.el.d2d 
        zT = Math.cos(scope.mt.rotY*Math.PI/180) * y + elZ;
        xT = -Math.sin(scope.mt.rotY*Math.PI/180) * y + elX;
        scope.el.left = xT + "px"
        scope.el.z = zT
      else if scope.keys.x || scope.transform == 'xy' 
        # and !scope.el.d2d  
         scope.el.anglex = angleX + x/2
         scope.el.angley = angleY + y/2
      else if scope.keys.z || scope.transform == 'rotate'  
        scope.el.angler = angleZ + x/2
      else if scope.transform == 'move' 
        yT = e.pageY - startY + elY
        xT = Math.cos(scope.mt.rotY*Math.PI/180) * x + elX;
        zT = Math.sin(scope.mt.rotY*Math.PI/180) * x + elZ;
        if scope.el.d2d
          xt = e.pageX - startX
          zt = scope.el.z 
        scope.el.top = yT + "px"
        scope.el.left = xT + "px"
        scope.el.z = zT

      $rootScope.selected = scope.el._id
      scope.$apply();

      if(okToUpdate)
        scope.elementFeed()
      okToUpdate = false;
      okToDeselect = false

    mouseupHandler = ->
      $document.unbind "mousemove", mousemove
      $document.unbind "mouseup", mouseupHandler
      # okToDeselect = true;
      # $document.unbind "mousedown", deselect

      # if !$rootScope.selected || !okToDeselect
      #   $rootScope.selected = scope.el._id
      #   okToDeselect = false;
      # else
      #   $rootScope.selected = null;
      # scope.$apply();

      scope.transform = 'move'
      scope.editElementFn()
      stopTimer()

    startTimer = ()->
      okToUpdate = true
      updateTimer = setInterval( ()->
        okToUpdate = true
        return null
      ,30)
    stopTimer = ()->
      clearTimeout(updateTimer);
      updateTimer =null;


    scope.openEditor = ()->
      # $parent.editElement = pageData.images | getById:$parent.selected; 
      scope.$parent.$parent.editMenu=!scope.$parent.$parent.editMenu
      okToDeselect = false;
      $rootScope.selected = scope.el._id

    scope.$on '$destroy', ()->
      $document.unbind "mousedown", deselect
      $document.unbind "mouseup", mouseupHandler
      el.unbind 'mousedown' 
      el.remove();




app.directive "page", ($document, $window)->
  templateUrl: '/partials/element'
  link:(scope, el, att) ->
    scope.keys = {}
    # scope.editMenu = true;

    rX = 0 
    rY = 0
    tx = 0
    tz = 0


    updateMt = ()->
      drx = rX- scope.mt.rotX
      dry = rY-scope.mt.rotY
      dz = tz - scope.mt.z 
      dx = tx - scope.mt.x 

      if Math.abs(drx)>1 then drx *= .2
      if Math.abs(dry)>1 then dry *= .2
      if Math.abs(dz)>1 then dz *= .2
      if Math.abs(dx)>1 then dx *= .2

      scope.mt.rotX += drx
      scope.mt.rotY += dry 
      scope.mt.x += dx 
      scope.mt.z += dz
      scope.$apply() 
      $window.requestAnimationFrame updateMt

    $window.requestAnimationFrame updateMt


    $document.on 'mousemove', (e) ->
      xRot =  +.5 - event.clientX/window.innerWidth;
      yRot =  - .5 + event.clientY/window.innerHeight;
      if scope.keys.space
        rX=yRot*300
        rY=xRot*300
      # else
      #   rX=yRot*30
      #   rY=xRot*30


    $document.on 'keydown', (e) ->
      switch e.which
        when 90 then scope.keys.z = true
        when 88 then scope.keys.x = true
        when 32  
          scope.keys.space = !scope.keys.space
          e.preventDefault()
        when 17 then scope.keys.cntrl = true
        when 38  
          tz +=  80
          # tz += Math.cos(scope.mt.rotY*Math.PI/180) * 100
          # tx -= Math.sin(scope.mt.rotY*Math.PI/180) * 100
          # e.preventDefault()
        when 40  
          tz -=  80
          # tz -= Math.cos(scope.mt.rotY*Math.PI/180) * 80
          # tx += Math.sin(scope.mt.rotY*Math.PI/180) * 80          
          # e.preventDeorfault()
        when 37 then rY -=20
        when 39 then rY +=20
    $document.on 'keyup', (e) ->
      switch e.which
        when 90 then scope.keys.z = false
        when 88 then scope.keys.x = false
        # when 32 then scope.keys.space = false
        when 17 then scope.keys.cntrl = false  

    scope.$on '$destroy', () ->
      $document.unbind 'keydown'    
      $document.unbind 'keyup'    




app.directive "embedSrc", ()->
  restrict: "A"
  link: (scope, element, attrs) ->
    current = element
    scope.$watch (->
      attrs.embedSrc
    ), ->
      clone = element.clone().attr("src", attrs.embedSrc)
      current.replaceWith clone
      current = clone

app.directive "soundcloud", ($timeout,$http) ->
  link: (scope, element, attrs) ->
    # scope.$watch 'el', () ->
    if(!scope.el.content.match('object') && !scope.el.content.match('iframe'))
      url = "http://soundcloud.com/oembed/?format=json&url="+scope.el.content+"&iframe=true"
      $http(
        method: 'GET' 
        url: url
        cache: true
        ).then (result) ->
                  scope.el.content=result.data.html; 
    $timeout(()->
      element.children().css
        width:'100%'
        height:'100%'
      return null
    ,4000)


# MAIN

app.directive "infinite",  ($window)->
  link:(scope, el, att) ->
      scrollDistance = 100
      $$window = angular.element(window);
      $$window.on 'scroll', (event) ->
        check(event)

      # TODO all? or one?
      check = (event)->
        if scope.scroll
          doc = document.documentElement;
          offsetTop = ($window.pageYOffset || doc.scrollTop)  - (doc.clientTop || 0);
          windowBottom = $window.innerHeight + offsetTop
          # windowBottom = el.parent()[0].offsetTop + el.parent()[0].offsetHeight

          elementBottom = el[0].offsetTop + el[0].offsetHeight
          remaining = elementBottom - windowBottom
          if remaining <= scrollDistance && elementBottom > 0
            scope.scroll = false
            scope.getNextPage()

      scope.$on '$destroy', () ->
        # $$window.unbind 'scroll'



app.directive "feed", ()->
  templateUrl: '/partials/feed'


app.directive "saveScroll", ($window, $timeout)->
  link:(scope, el, att) ->

    scope.$watch 'showMain', (newP, oldP)->
      if newP == true
        $timeout ->
          window.scroll(0, scope.scroll)
          return
        ,10
      else
        doc = document.documentElement;
        scroll = ($window.pageYOffset || doc.scrollTop)  - (doc.clientTop || 0);
        # angular.element($window).unbind 'scroll', resetWindow
        scope.saveScroll(scroll)

    # resetWindow = ()->
    #   angular.element(document.body).css
    #     height: '100%'

    # $timeout ()->
    #   if scope.scroll
    #     # angular.element(document.body).scrollTop(scope.scroll)
    #     # angular.element(document.html).scrollTop(scope.scroll)

    #     # TODO fix auto scroll
    #     angular.element(document.body).css
    #       height: scope.scroll + 1000 + 'px'

    #       window.scroll(0, scope.scroll)
    #       window.scrollTo(0, scope.scroll)

    #     angular.element($window).on 'scroll', resetWindow


    #     # angular.element($window).scrollTop(scope.scroll)
    #     # scope.$apply()
    #   return null

    # , 30

    # scope.$on '$destroy', () ->
    #   if scope.pageName == 'main'
    #     doc = document.documentElement;
    #     scroll = ($window.pageYOffset || doc.scrollTop)  - (doc.clientTop || 0);
    #     angular.element($window).unbind 'scroll', resetWindow
    #     scope.saveScroll(scroll)

app.directive "gallery", ($window)->
  templateUrl: '/partials/gallery'




app.directive "appVersion", (version) ->
  (scope, elm, attrs) ->
    elm.text version
