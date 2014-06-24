db={}
mongoose = require('mongoose')
db.pageModel = mongoose.model('pageModel')
db.userModel = mongoose.model('userModel')
db.textModel = mongoose.model('textModel')
db.imageModel = mongoose.model('imageModel')

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
  everyone.now.elementFeed = (pageName, element) ->
    
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
    nowjs.getGroup(pageId).exclude(oldthis.user.clientId).now.newElement [element]

  everyone.now.editElement = (options, element, callback) ->

    pageId = @user.currentPage
    allowed = checkPermissions(@user)
    if !allowed 
      if callback 
        callback "this page is private, you can't make changes"
      return


    oldthis = this
    _id = element._id
    db.pageModel.findOne
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
        console.log result.images.id(_id).url
        console.log  element.url

        result.save (error, result) ->
          unless error
            # if position
            nowjs.getGroup(pageId).exclude(oldthis.user.clientId).now.newElement [element]
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
      imgs.push new db.imageModel(imgArray[i])

      img = imgArray[i]



      i++
    console.log imgs
    
    #TODO: real update feed?

    # db.pageModel.findOne
    #   _id: pageId
    # , (err, page)->
    #   if !err && page
    #     for img in imgs
    #       page.images.push(img)
    #     page.save (err, res)->
    #       notify = {} #new notifyModel();
    #       notify.user = oldthis.user.name
    #       notify.action = "update"
    #       notify.page = pageId
    #       nowjs.getGroup(pageId).now.newElement imgs
          
          

    db.pageModel.update
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
        nowjs.getGroup(pageId).now.newElement imgs
        
        #nowjs.getGroup('main').now.notify([notify],null, true)
        # need update notifications?   
        # everyone.now.notify [notify], null, true
        for img in imgs
          media.addToMedia img, pageId, oldthis.user.userId, options





    #           media.uploadToS3(img.url,null)

      else
        console.log err








  everyone.now.updateUserPic = (username, url, callback) ->
    oldthis = this
    unless username is @user.name
      callback "error"
      return
    else
      db.userModel.update
        username: username
      ,
        $set:
          userImage: url
      , (error) ->
        oldthis.user.image = url
        # unless error
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
      db.pageModel.findOne
        _id: pageId
      , (error, result) ->
        result.images = []
        result.save (error) ->
          nowjs.getGroup(pageId).now.deleteResponce imgId, all  unless error


    else
      db.pageModel.findOne
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
    
    db.pageModel.update
      _id: pageId
    ,
      $set:
        backgroundImage: bg.image ? ""
        background: bg.color ? ""
        bgDisplay: bg.display ? ""

    , (err) ->
      unless err
        nowjs.getGroup(pageId).now.updateBackground bg

        options.bg = true;
        media.addToMedia img, pageId, oldthis.user.userId, options

      else
        callback err
        console.log err




  everyone.now.setProfileBackground = (userProfile, bg, callback) ->
    if userProfile != @user.name
      return
      
    db.userModel.update
      username: userProfile
    ,
      $set:
        backgroundImage: bg.image ? ""
        background: bg.color ? ""
        bgDisplay: bg.display ? ""      
    , (err) ->
      unless err
        callback()
        nowjs.getGroup(pageName).now.updateBackground bg
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
    txt = new db.textModel(textObject)
    txt.user = @user.name
    txt.text = textObject.text
    thereIsError = false
    if pageName is "profile"
      # groupName = "profile___" + userProfile
      db.userModel.update
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
      db.pageModel.update
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
    db.userModel.find
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
    db.pageModel.find
      pageName: page
    ,
      pageName: 1
    , (error, result) ->
      unless error
        callback result
      else
        console.log error

  checkPermissions = (user)->
    if !user || !user.currentPage || !user.pagePermissions[user.currentPage]
      return false
    pageId = user.currentPage
    if user.pagePermissions[pageId] > 0 and user.pagePermissions[pageId] isnt "owner"
      return false
    else
      return true

