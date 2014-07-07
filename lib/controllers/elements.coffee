mongoose = require('mongoose')
pageModel = mongoose.model('pageModel')
userModel = mongoose.model('userModel')
textModel = mongoose.model('textModel')
imageModel = mongoose.model('imageModel')
mediaModel = mongoose.model('mediaModel')

# notifyUsers = require('./notify')


isUrl = (s)->
  regexp = /(ftp|http|https):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/
  return regexp.test(s);



module.exports = (everyone, nowjs) ->

  media = require('./media')(everyone, nowjs)


  notifyUsers = require('./notify')(everyone,nowjs)

  #///////////
  #/ELEMENTS
  #////////

  #var liveStream=[];
  everyone.now.elementFeed = (pageName, element, callback) ->
    
    pageId = @user.currentPage
    allowed = checkPermissions(@user)
    if !allowed 
      if callback 
        callback "this page is private, you can't make changes"
      return

    oldthis = this

    # console.log('feed')
    # thisUpdate =
    #   clientId: oldthis.user.clientId
    #   pageName: pageName
    #   properites: properties
    #   elId: _id

    #liveStream.push(thisUpdate);
    # nowjs.getGroup(pageName).exclude(oldthis.user.clientId).now.updateChanges _id, properties
    nowjs.getGroup(pageId).exclude(oldthis.user.clientId).now.updateElement [element], {replaceUrl:false}

  everyone.now.editElement = (options, element, callback) ->

    pageId = @user.currentPage
    allowed = checkPermissions(@user)
    if !allowed 
      if callback 
        callback "this page is private, you can't make changes"
      return


    oldthis = this
    _id = element._id
    pageModel.findOne
      _id: pageId
      "images._id": _id
    , (error, result) ->
      if error
        console.log(error)
      else
        #console.log(element);    
        # if all and element.type is "image"
        #   result.images.forEach (image) ->
        #     image = element  if image.type is "image"
        # else
        unless options && options.replaceUrl == true
          console.log "not replacing url"
          element.url = result.images.id(_id).url
        result.images.id(_id).set element
        # console.log result.images.id(_id).url
        # console.log  element.url



        result.save (error, result) ->
          unless error
            # if position
            if !options
              options={}
              options.replaceUrl=false
            nowjs.getGroup(pageId).exclude(oldthis.user.clientId).now.newElement [element], {replaceUrl:options.replaceUrl}
            # else
              # nowjs.getGroup(pageId).now.newElement [element]
          #console.log(images)
          else
            console.log error




  #/////
  #/ADD
  #///
  everyone.now.addNewImg = (options, imgArray, callback) ->
    pageId = @user.currentPage
    allowed = checkPermissions(@user)
    if !allowed 
      callback "this page is private, you can't make changes"
      return

    oldthis = this 

    imgs = []
    i = 0

    while i < imgArray.length
      if imgArray[i].contentType is "image" and not isUrl(imgArray[i].url)
        callback "invalid image url"
        continue
      imgArray[i].user = @user.name
      imgs.push new imageModel(imgArray[i])

      img = imgArray[i]



      i++
    console.log imgs
    
    #TODO: real update feed?          

    pageModel.update
      _id: pageId
    ,
      $pushAll:
        images: imgs
    , (err, result) ->
      unless err
        notify = {} #new notifyModel();
        notify.user = oldthis.user.name
        notify.action = "update"
        notify.page = pageId
        nowjs.getGroup(pageId).now.newElement imgs, {replaceUrl:true}
        
        #nowjs.getGroup('main').now.notify([notify],null, true)
        # need update notifications?   
        # everyone.now.notify [notify], null, true

        # callback for addToMedia
        updatePage = (img,mediaId,options)->
          pageId = options.pageId
          pageModel.update
            _id : pageId
            'images._id' : img.id
          ,
            $set: 
              'images.$.mediaId': mediaId
              'images.$.url': img.url
          , (err) ->
            if !err 
              console.log "updated page img mediaID"
              nowjs.getGroup(pageId).now.updateElement [img],  {replaceUrl:true}

        options =
          callback: updatePage
          pageId : pageId
          userId: oldthis.user.userId 

        for img in imgs
          media.addToMedia img, options





    #           media.uploadToS3(img.url,null)

      else
        console.log err








  everyone.now.updateUserPic = (username, url, callback) ->
    oldthis = this

    updateUserPic = (img, mediaId, options)->
      userId = options.userId
      userModel.update
        _id : userId
      ,
        $set:
          userImageId: mediaId
          userImage: img.url
      , (err)->
        if err 
          console.log err
        else 
          console.log 'updated user bgId' 
    


    unless username is @user.name
      callback "error"
      return
    else
      userModel.update
        username: username
      ,
        $set:
          userImage: url
      , (error) ->
        oldthis.user.image = url
        unless error
          options =
            callback: updateUserPic
            userId: oldthis.user.userId
            user: true
 
          media.addToMedia {contentType:'image', url: url}, options

          # TODO implement
          # everyone.now.updateUsrImg username, url
        callback(error)





  #////////
  #/DELETE
  #//////
  everyone.now.deleteElement = (pageName, imgId, all, callback) ->
    pageId = @user.currentPage
    allowed = checkPermissions(@user)
    if !allowed 
      callback "this page is private, you can't make changes"
      return

      
    if all
      pageModel.findOne
        _id: pageId
      , (error, result) ->
        result.images = []
        result.save (error) ->
          nowjs.getGroup(pageId).now.deleteResponce imgId, all  unless error


    else
      pageModel.findOne
        _id: pageId
      , (error, result) ->
        unless result.images.id(imgId) is `undefined`
          result.images.id(imgId).remove()
          result.save (error) ->
            nowjs.getGroup(pageId).now.deleteResponce imgId, all  unless error



  #///////////
  #BACKGROUND
  #/////////
  everyone.now.setBackground = (bg, options, callback) ->
    
    pageId = @user.currentPage
    allowed = checkPermissions(@user)
    if !allowed 
      callback "this page is private, you can't make changes"
      return
    
    oldthis = this 

    pageModel.update
      _id: pageId
    ,
      $set:
        backgroundImage: bg.image ? ""
        background: bg.color ? ""
        bgDisplay: bg.display ? ""

    , (err) ->
      unless err
        nowjs.getGroup(pageId).now.updateBackground bg

        # callback for addToMedia (only updates mediaId)
        updatePage = (img,mediaId,options)->
          pageId = options.pageId
          pageModel.update
            _id : pageId
          ,
            $set: 
              'backgroundImageId': mediaId
              'backgroundImage': img.url
          , (err) ->
            if !err 
              console.log "updated page backgroundImg mediaID"
              bg.image = img.url
              nowjs.getGroup(pageId).now.updateBackground bg

        options =
          pageId : pageId
          callback: updatePage
          userId: oldthis.user.userId
          bg: bg 
          img: options.img

        if bg.image && options.img
          media.addToMedia {contentType:'image', url: bg.image}, options




      else
        callback err
        console.log err




  everyone.now.setProfileBackground = (bg, options, callback) ->
    

    if encodeURIComponent(@user.currentPage) != encodeURIComponent(@user.userId)
      return
    
    userId =  @user.userId
    oldthis = this

    updateUserBg = (img, mediaId, options)->
      userId = options.userId
      userModel.update
        _id : userId
      ,
        $set: 
          backgroundImageId: mediaId
          backgroundImage: img.url
      , (err)->
        if err 
          console.log err
        else 
          console.log 'updated user bgId' 
          nowjs.getGroup(userId).now.updateBackground 
              image: img.url
              imgOnly: true

    userModel.update
      _id: userId
    ,
      $set:
        backgroundImage: bg.image ? ""
        background: bg.color ? ""
        bgDisplay: bg.display ? ""      
    , (err) ->
      unless err
        callback()
        console.log nowjs.getGroup(oldthis.user.userId)
        nowjs.getGroup(oldthis.user.userId).now.updateBackground bg
      
        options =
          callback: updateUserBg
          userId: oldthis.user.userId
          user: true
          bg: bg 
          img: options.img

        if bg.image && options.img
          media.addToMedia {contentType:'image', url: bg.image}, options



      else
        console.log err




  #/////////////
  #////TXT/////
  #///////////
  everyone.now.submitComment = (pageName, textObject, userProfile) ->
    
    #pageName=this.user.currentPage;
    return  if @user.name is "n00b" and pageName isnt "invite"
    oldthis = this
    
    pageId = @user.currentPage


    #TODO: permissions
    groupName = pageId
    txt = new textModel(textObject)
    txt.user = @user.name
    txt.text = textObject.text
    thereIsError = false
    if pageName is "profile"
      # groupName = "profile___" + userProfile
      userModel.update
        _id: pageId
      ,
        $push:
          text: txt
      , (err) ->
        
        #console.log("This is groupName %", groupName);
        unless err
          notifyUsers [], userProfile, oldthis.user.name, oldthis.user.image, "msg", ""
          nowjs.getGroup(pageId).now.updateText oldthis.user.name, txt.text

    else
      
      #nowjs.getGroup(pageName).now.updateText(this.user.name,textObject.text);
      pageModel.update
        _id: pageId
      ,
        $push:
          text: txt
      , (err) ->
        if err
          console.log err
        else
          nowjs.getGroup(pageId).now.updateText oldthis.user.name, txt.text


  everyone.now.findUser = (userTxt, callback) ->
    user = new RegExp("^" + userTxt, "i")
    userModel.find
      username: user
    ,
      username: 1
    , (error, result) ->
      unless error
        callback result
      else
        console.log error


  everyone.now.findPage = (page, callback) ->
    user = new RegExp("^" + page, "i")
    pageModel.find
      pageName: page
    ,
      pageName: 1
    , (error, result) ->
      unless error
        callback result
      else
        console.log error

  checkPermissions = (user)->

    if !user || !user.currentPage || user.pagePermissions[user.currentPage] == undefined
      return false
    pageId = user.currentPage
    if user.pagePermissions[pageId] > 0 and user.pagePermissions[pageId] isnt "owner"
      return false
    else
      return true

