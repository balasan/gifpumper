"use strict"

# Filters 
app = angular.module("gifpumper")

# app.filter "fusetext", ()->
#   (data)->
#     if(data)
#       dataCopy = data.slice()
#       last
#       lastText=''
#       fused = []
#       for el in dataCopy
#         if !last || last.user != el.user
#           fused.push(el)
#           last = el
#           lastText=el.text
#           fused[fused.length-1].text = lastText
#         else
#           lastText += el.text
#       return fused

app.filter "contentType", ()->
  (contentType) ->
    switch contentType
      when 'image' then return "image"
      when 'youtube' || 'soundcloud' || 'vimeo' || 'custom' then return "media"
      when 'text' then return "text"
      when 'div' then return "div"
      else 'image'


app.filter "getByName", ()->
  (array, name) ->
    for el, i in array
      if el.pageName == name 
        return i

app.filter "getById", ()->
  (array, id) ->
    for el, i in array
      if el._id == id 
        return i

app.filter "privacy", [ ()->
  (number) ->
    switch number
      when 0 then return "public"
      when 1 then return "semi-private"
      when 2 then return "private"
]

app.filter 'timeago', [ ()->
    (date) ->
      if(date!="")
        moment(date).fromNow();
      else
        "a while ago"
]

app.filter 'unsafe',['$sce', ($sce) ->
  (val) ->
    $sce.trustAsHtml(val);
]

# app.filter "interpolate", [() ->
#   (text) ->
#     String(text).replace /\%VERSION\%/g, version
# ]

app.filter 'encode', () ->
     window.encodeURIComponent


app.filter 'transition', () ->
  (el) ->
    'translateZ('+(if el.z then el.z else 0)+ 'px) rotateY('+(if el.anglex then el.anglex else 0)+'deg) rotateX(' +(if el.angley then el.angley else 0)+'deg) rotateZ(' +(if el.angler then el.angler else 0)+ 'deg)'


app.filter 'mainTransform', () ->
  (mt) ->
      'translateZ('+(if mt.z then mt.z else 0)+ 'px) rotateY('+(if mt.rotY then mt.rotY else 0)+'deg) rotateX('+(if mt.rotX then mt.rotX else 0)+'deg)' 
      # translateZ('+(if mt.z then mt.z else 0)+ 'px)\ 
      # translateX('+(if mt.x then mt.x else 0)+ 'px)'

app.filter 'youtube', ($sce) ->
  (content, type) ->
    if !content
      return;
    video_id = content.split("v=")[1]
    unless video_id is `undefined`
      ampersandPosition = video_id.indexOf("&")
      video_id = video_id.substring(0, ampersandPosition)  unless ampersandPosition is -1
    
    if type == "object" 
      src = $sce.trustAsResourceUrl("http://www.youtube-nocookie.com/v/"+video_id+"?autoplay=1&loop=1&version=3&hl=en_US")
    if type == "iframe"
      src = $sce.trustAsResourceUrl("http://www.youtube.com/embed/"+video_id+"?autoplay=1&loop=1")
    src


app.filter 'vimeo', ($sce) ->
  (content, type) ->
    video_id = content.split('vimeo.com/')[1];
    if type == "object" 
      src = $sce.trustAsResourceUrl('http://vimeo.com/moogaloop.swf?clip_id='+video_id+'&amp;server=vimeo.com&amp;show_title=0&amp;show_byline=0&amp;show_portrait=0&amp;color=00adef&amp;fullscreen=1&amp;autoplay=1&amp;loop=1')
    if type == "iframe"
      src = $sce.trustAsResourceUrl("//player.vimeo.com/video/"+video_id+"?autoplay=1&loop=1")
    src


app.filter 'soundcloud', ($sce, $http) ->
  (content) ->
    # return ""
    # content = $sce.trustAsHtml(content.replace('height=\"166\"','height=\"100%\"'))
    content = $sce.trustAsHtml(content)


app.filter 'trusted', ($sce, $http) ->
  (content) ->
    # return ""
    # content = $sce.trustAsHtml(content.replace('height=\"166\"','height=\"100%\"'))
    content = $sce.trustAsResourceUrl(content)


# TODO: split up backgoundImage and backgroundGradient
app.filter 'bgFilter', ($filter) ->
  (pageObj) ->
    color = ''
    img = ''
    size = ''
    gradient =''
    if pageObj.background and pageObj.background != ''
      color = pageObj.background
    if pageObj.backgroundImage and pageObj.backgroundImage != ''
      if pageObj.backgroundImage.match("background:") == null
        img = 'url('+pageObj.backgroundImage+')'
      else
        gradient = pageObj.backgroundImage
        gradient = gradient.replace(/;/g, "")
        if gradient.match("background-image:")
          gradient = gradient.split("background-image:")
        else if gradient.match("background:")
          gradient = gradient.split("background:") 
          gradient = gradient

    if pageObj.bgDisplay and pageObj.bgDisplay != ''
      size = pageObj.bgDisplay
    style = 
      backgroundImage : img
      backgroundGradient : gradient      
      backgroundColor : color 
      backgroundSize : size 


# GALLERY
app.filter "galleryThumb", () ->
  (page) ->
    imgUrl
    if page.backgroundImage
      imgUrl = page.backgroundImage
    else
      imgUrl = ""
      # TODO better solution?
      for image in page.images
        if(image and image.url and image.url !="")
          imgUrl = image.url
          break
      # angular.forEach page.images, (image) ->
      #   if(image.url != "" && imgUrl == "")
      #     imgUrl = image.url
      #     return ''
    imgUrl


# FEED

app.filter "profileThumb", () ->
  (url) ->
    if(!url)
      "http://dumpfm.s3.amazonaws.com/images/20110926/1317014842765-dumpfm-FAUXreal-1297659023374-dumpfm-frankhats-yes.gif"
    else url


app.filter 'action',  () ->
  (action) ->
    switch action
      when 'version' then return "saved"
      when 'like' then return "likes"
      when 'new' then return "created"


app.filter 'owner', () ->
  (owner,user) ->
    if owner == user
      'owner'
    else
      'editor'


app.filter 'version',  () ->
  (version) ->
    if version != undefined
      '/'+version
    else
      ''


app.filter 'versionText',  () ->
  (version) ->
    if version != undefined
      version+'v'
    else ''



