"use strict"

# Directives 
app = angular.module("gifpumper")



app.directive "thumbnail", ($filter)->
  link:(scope,el,att)->
    # page = att.page
    page = scope.page
    imgUrl="http://25.media.tumblr.com/tumblr_lbhdk9rfdN1qal30oo1_400.gif"
    currentImg=0
    lastUrl=""
    img = el.find('img')

    cycleImg = (start)->
      # TODO better solution?
      if page.images
        for i in [start...page.images.length]
          image = page.images[i]
          if image and image.url and $filter('isUrl')(image.url) && lastUrl != image.url
            imgUrl = image.url
            currentImg = i
            break
          currentImg = i

    if $filter('isUrl')(page.backgroundImage)
      imgUrl = page.backgroundImage
    else
      cycleImg(0)

    img[0].src=imgUrl
    lastUrl = imgUrl

    img.on 'error', (e)->
      if page.images.length>currentImg+1
        cycleImg(currentImg+1)
      else
        imgUrl="http://25.media.tumblr.com/tumblr_lbhdk9rfdN1qal30oo1_400.gif"
        
      img[0].src=imgUrl
      lastUrl = imgUrl


    scope.$on '$destroy', ()->
      img.unbind 'error'

app.directive "freeze", ($filter, $timeout)->
  link:(scope,el,att)->
    width = parseInt(att.w)
    height = parseInt(att.h)
    img = el.find('img')

    c=null
    img.on 'load', (e)->
      if $filter('isGif')(img[0]) && (img[0].naturalWidth > width or img[0].naturalHeight > height) 
        c = $filter('freezeGif')(img[0])
        c.style.width = '100%'
        c.style.height= 'auto'
        c.style.display= 'block'

        img[0].parentNode.appendChild c
        img.css
          display: 'none'

    timeout=null
    el.on 'mouseenter', (e)->
      if c
        timeout = $timeout ()->
          img.css
            display: 'block'
          angular.element(c).css
            display: 'none'
          return
        ,100

    el.on 'mouseleave', (e)->
      $timeout.cancel(timeout)
      if c
        img.css
          display: 'none'
        angular.element(c).css
          display: 'block'

    scope.$on '$destroy', ()->
      el.unbind 'mouseleave'
      el.unbind 'mouseenter'
      img.unbind 'load'

