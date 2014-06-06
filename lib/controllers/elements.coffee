db={}
mongoose = require('mongoose')
db.pageModel = mongoose.model('pageModel')
db.userModel = mongoose.model('userModel')
db.textModel = mongoose.model('textModel')
db.imageModel = mongoose.model('imageModel')
# notifyUsers = require('./notify')


module.exports = (everyone, nowjs) ->

  notifyUsers = require('./notify')(everyone,nowjs)

  #///////////
  #/ELEMENTS
  #////////

  #var liveStream=[];
  everyone.now.elementFeed = (pageName, element) ->
    return  if @user.pagePermissions[pageName] is `undefined` or @user.pagePermissions[pageName] > 1
    oldthis = this

    # console.log('feed')
    # thisUpdate =
    #   clientId: oldthis.user.clientId
    #   pageName: pageName
    #   properites: properties
    #   elId: _id

    
    #liveStream.push(thisUpdate);
    # nowjs.getGroup(pageName).exclude(oldthis.user.clientId).now.updateChanges _id, properties
    nowjs.getGroup(pageName).exclude(oldthis.user.clientId).now.newElement [element]

  everyone.now.editElement = (pageName, element, all, position) ->
    return  if @user.pagePermissions[pageName] is `undefined` or @user.pagePermissions[pageName] > 1
    oldthis = this
    _id = element._id
    db.pageModel.findOne
      pageName: pageName
      "images._id": _id
    , (error, result) ->
      if error
        console.log(error)
      else
        #console.log(element);    
        if all and element.type is "image"
          result.images.forEach (image) ->
            image = element  if image.type is "image"

        else
          result.images.id(_id).set element
        result.save (error, result) ->
          unless error
            if position
              nowjs.getGroup(pageName).exclude(oldthis.user.clientId).now.newElement [element]
            else
              nowjs.getGroup(pageName).now.newElement [element]
          #console.log(images)
          else
            console.log error




  #/////
  #/ADD
  #///
  everyone.now.addNewImg = (pageName, imgArray, callback) ->
    oldthis = this
    if @user.pagePermissions[pageName] > 0 and @user.pagePermissions[pageName] isnt "owner"
      callback "this page is private, you can't add images"
      return
    imgs = []
    i = 0

    while i < imgArray.length
      if imgArray[i].type is "image" and not isUrl(imgArray[i].url)
        callback "invalid image url"
        continue
      imgArray[i].user = @user.name
      imgs.push new db.imageModel(imgArray[i])
      i++
    console.log imgs
    
    #TODO: real update feed?
    db.pageModel.update
      pageName: pageName
    ,
      $pushAll:
        images: imgs
    , (err, result) ->
      unless err
        notify = {} #new notifyModel();
        notify.user = oldthis.user.name
        notify.action = "update"
        notify.page = pageName
        nowjs.getGroup(pageName).now.newElement imgs
        
        #nowjs.getGroup('main').now.notify([notify],null, true)   
        everyone.now.notify [notify], null, true
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
    if @user.pagePermissions[pageName] > 0 and @user.pagePermissions[pageName] isnt "owner"
      callback "this page is private, you can't delete images"
      return
    if all
      db.pageModel.findOne
        pageName: pageName
      , (error, result) ->
        result.images = []
        result.save (error) ->
          nowjs.getGroup(pageName).now.deleteResponce imgId, all  unless error


    else
      db.pageModel.findOne
        pageName: pageName
      , (error, result) ->
        unless result.images.id(imgId) is `undefined`
          result.images.id(imgId).remove()
          result.save (error) ->
            nowjs.getGroup(pageName).now.deleteResponce imgId, all  unless error



  #///////////
  #BACKGROUND
  #/////////
  everyone.now.setBackground = (pageName, bg, callback) ->
    
    #TODO: tweak this
    pageName = @user.currentPage
    if @user.pagePermissions[pageName] is `undefined` or @user.pagePermissions[pageName] > 0 and @user.pagePermissions[pageName] isnt "owner"
      callback "this page is private, you can't edit background"
      return
    
    db.pageModel.update
      pageName: pageName
    ,
      $set:
        backgroundImage: bg.image ? ""
        background: bg.color ? ""
        bgDisplay: bg.display ? ""

    , (err) ->
      unless err
        nowjs.getGroup(pageName).now.updateBackground bg
      else
        callback err
        console.log err




  everyone.now.setProfileBackground = (userProfile, bg, callback) ->
    pageName = "profile___" + userProfile
    if @user.pagePermissions[pageName] is `undefined` or @user.pagePermissions[pageName] > 0 and @user.pagePermissions[pageName] isnt "owner"
      console.log @user.pagePermissions[pageName]
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
    
    #TODO: permissions
    groupName = pageName
    txt = new db.textModel(textObject)
    txt.user = @user.name
    txt.text = textObject.text
    thereIsError = false
    if pageName is "profile"
      groupName = "profile___" + userProfile
      db.userModel.update
        username: userProfile
      ,
        $push:
          text: txt
      , (err) ->
        
        #console.log("This is groupName %", groupName);
        unless err
          notifyUsers [], userProfile, oldthis.user.name, oldthis.user.image, "msg", ""
          nowjs.getGroup(groupName).now.updateText oldthis.user.name, txt.text

    else
      
      #nowjs.getGroup(pageName).now.updateText(this.user.name,textObject.text);
      db.pageModel.update
        pageName: pageName
      ,
        $push:
          text: txt
      , (err) ->
        if err
          console.log err
        else
          nowjs.getGroup(pageName).now.updateText oldthis.user.name, txt.text


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

