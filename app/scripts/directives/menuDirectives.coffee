"use strict"

# Directives 
app = angular.module("gifpumper")

app.directive "editMenu", ($document,$filter)->
  link:(scope,el,att)->
    scope.$watch 'selected', (newEl, oldEl)->
      if(newEl != oldEl)
        id = $filter('getById')(scope.pageData.images, scope.selected) 
        scope.editElement = scope.pageData.images[id]
        if scope.editElement != undefined
          scope.editType= $filter('contentType')(scope.editElement.contentType) 

    scope.replaceElement = ()->

      scope.editElement.contentType = scope.editType
      if scope.editType == 'media'
        if scope.editElement.content.match('youtube')
          scope.editElement.contentType = 'youtube'  
        else if scope.editElement.content.match('soundcloud')
          scope.editElement.contentType = 'soundCloud'
        else if scope.editElement.content.match('vimeo')
          scope.editElement.contentType = 'vimeo'
        else if scope.editElement.content.match('.mp3')
          scope.editElement.contentType = 'mp3Url'
        else
          scope.editElement.contentType = ''
      angular.element( document.getElementById(scope.editElement._id)).scope().editElementFn()
      


app.directive "addMenu", ($document)->
  link:(scope,el,att)->
    scope.addNewImg = ->
      unless scope.pageData.version is `undefined`
        alert "You can't edit saved versions"
        return

      number = scope.imageNumber
      is2d = scope.is2d
      imgUrl = scope.newImgUrl

      if pageName is "profile"
        now.updateUserPic scope.userProfile, imgUrl, (error) ->
          document.getElementById("userImage").src = imgUrl  unless error
          return
        return

      scrollTop = document.body.scrollTop
      scrollLeft = document.body.scrollLeft

      if scrollTop is 0
        if window.pageYOffset
          scrollTop = window.pageYOffset
          scrollLeft = window.pageXOffset
        else
          scrollTop = (if (document.body.parentElement) then document.body.parentElement.scrollTop else 0)
          scrollLeft = (if (document.body.parentElement) then document.body.parentElement.scrollLeft else 0)
      elArray = []
      i = 0

      while i < number
        addObject = {}
        addObject.d2d = is2d
        
        #TODO RESET RADIOS!
        addObject.top = Math.random() * 500 + scrollTop + "px"
        addObject.left = -scope.mt.x + Math.random() * 900 + scrollLeft + "px"
        if scope.addType is "div" or scope.addType is "text"
          addObject.height = "300px"
          addObject.width = "400px"
        else
          addObject.height = "auto"
          addObject.width = "auto"
        addObject.z = Math.random() * 50 - scope.mt.z
        
        #addObject.left +=mainDivTrasfrom.x
        addObject.angler = 0
        addObject.anglex = -scope.mt.rotY
        addObject.angley = 0
        if scope.geoPreset is "hPlane"
          addObject.angley = 90
          addObject.height = "1000px"
          addObject.width = "1000px"
          addObject.z = -500
        else if scope.geoPreset is "vPlane"
          addObject.anglex = 90
          addObject.width = "1000px"
          addObject.height = "1000px"
          addObject.z = -500
        
        scope.geoPreset = false

        addObject.contentType = scope.addType
        if scope.addType is "image"
          addObject.url = imgUrl
        else if scope.addType is "media"
          if scope.youtubeUrl && scope.youtubeUrl != ""
            addObject.content = scope.youtubeUrl
            addObject.contentType = "youtube"
            addObject.width = "450px"
            addObject.height = "300px"
          else if scope.soundcloudUrl && scope.soundcloudUrl != ""
            addObject.content = scope.soundcloudUrl
            addObject.contentType = "soundCloud"
            addObject.width = "300px"
            addObject.height = "81px"
          else if scope.vimeoUrl && scope.vimeoUrl != ""
            addObject.content = scope.vimeoUrl
            addObject.contentType = "vimeo"
            addObject.width = "450px"
            addObject.height = "300px"
          else if scope.mp3Url && scope.mp3Url != ""
            addObject.content = mp3Url
            addObject.contentType = "mp3"
            addObject.width = "450px"
            addObject.height = "300px"
          else
            addObject.content = scope.customMedia
          number = 1
        else addObject.content = scope.text  if scope.addType is "text"
        if scope.addType is "div"
          addObject.backgroundColor = scope.divColor
          addObject.backgroundImage = scope.divBackground
          number = 1
        elArray.push addObject
        i++
      scope.addNewImgCtrl elArray
     