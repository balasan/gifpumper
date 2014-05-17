
db={}
mongoose = require('mongoose')
db.pageModel = mongoose.model('pageModel')
db.userModel = mongoose.model('userModel')
db.onlineModel = mongoose.model('onlineModel')
# nowjs = require('now')

module.exports = (everyone, nowjs, sessionStore) ->

  # parseCookie = require('cookie').parseSignedCookies;

  # parseCookie = require('connect').utils.parseSignedCookie;
  #///////
  #/INITS
  #/////
  inviteCode =
    pumpLove93: 1
    pumpEyebeam: 1
    innerPump: 1
    fbPump: 1
    "319Pump": 1

  everyone.now.currentUser = (callback)->
    callback(this.user.name);

  everyone.now.checkInvite = (invite, callback) ->
    unless inviteCode[invite] is `undefined`
      callback true
    else
      callback false

  everyone.on "join", ->
    @user.name = "n00b"
    cookie = @user.cookie["connect.sid"]
    if cookie is `undefined` or not cookie?
      @user.name = "n00b"
      return    

    console.log(cookie)
    cookie = unescape(cookie).split('.')[0].slice(2)
    oldthis = this

    # cookie = require('cookie').parseSignedCookies(@user.cookie, "woagifs");

    sessionStore.get cookie, (err, session) ->
      if err
        console.log err
        console.log "something is wrong"
        oldthis.user.name = "n00b"
        return
      else
        console.log(session)
        console.log(session.user)
        if session != undefined and session.passport.user != undefined
          
          # oldthis.user.name = session.user
          db.userModel.findOne
            _id: session.passport.user
          ,
            userImage: 1
            username: 1
            notify:
              $slice:-50
            newNotify: 1
          , (err, result) ->
            if !err
              oldthis.user.image = result.userImage 
              oldthis.user.name = result.username 
              
              # too quick doesn't work :\
              setTimeout ()->
                if oldthis.now.notifyUser
                  oldthis.now.notifyUser result.notify, result.newNotify
              , 1000

        else
          oldthis.user.name = "n00b";
          # return;
        console.log oldthis.user.name + " connected"


  everyone.now.resetNewNotify = ()->
    oldthis = this
    db.userModel.update
      username: oldthis.user.name
    ,
      $set:
        newNotify: 0
        notify: result.notify
        nowId: oldthis.user.clientId
    , (err) ->
      console.log err  if err


  # delete this
  everyone.now.getNotifications = ->
    return  if @user.name is "n00b" or @user.name is undefined
    console.log(@user.name)
    oldthis = this
    db.userModel.findOne
      username: oldthis.user.name
    ,
      notify:
        $slice: -50

      newNotify: 1
    , (err, result) ->
      unless err
        result.newNotify = 0  if result? and result.newNotify is `undefined`
        unless oldthis.now.notify is `undefined`
          oldthis.now.notify result.notify, result.newNotify
          db.userModel.update
            username: oldthis.user.name
          ,
            $set:
              newNotify: 0
              notify: result.notify
              nowId: oldthis.user.clientId
          , (err) ->
            console.log err  if err



  everyone.now.getUserPic = (username, callback) ->
    db.userModel.findOne
      username: username
    ,
      userImage: 1
    , (err, res) ->
      callback res.userImage, username  unless err


  everyone.now.getPagePic = (page, callback) ->
    db.pageModel.findOne
      pageName: page
    ,
      backgroundImage: 1
      "images.url": 1
      background: 1
    , (err, res) ->
      if not err and res?
        url = undefined
        img = undefined
        url = res.backgroundImage  if res? and res.backgroundImage isnt `undefined` and res.backgroundImage isnt ""
        img = res.images[0].url  if res? and res.images isnt `undefined` and res.images[0] isnt `undefined` and res.images[0] isnt ""
        color = res.background
        callback url, img, color, page
      else
        console.log err


  everyone.now.updateAll = (pageData, callback) ->
    for page of pageData
      db.pageModel.update
        pageName: page
      , pageData[page]["pageData"],
        upsert: true
        multi: false
      , (error) ->
        console.log error  if error

  everyone.now.loadUserProfile = (user, callback) ->
    db.userModel.findOne
      username: user
    ,
      password: 0
      salt: 0
    , (error, result) -> 
      if !error
        callback null, result
      else
        callback error 

  # TODO: sanitize user urls
  # db.userModel.find (err, res) ->
  #   for user in res 
  #       if user.backgroundImage && user.backgroundImage.match(/url\(/)
  #         console.log user.backgroundImage 

  everyone.now.loadUserPages = (user, page, number, filter, callback) ->

    startN = page * number
    dbFilter = filter
    dbFilter = "likesN"  if filter is "likes"
    dbFilter = "edited"  if filter is "updated"

    db.pageModel.find(
      $or: [
        owner: user
      ,
        "images.user": user
      ]
    ).sort( "-"+dbFilter+" "+"pageName").skip(startN).limit(number).exec (err, pages) ->
      if !err && pages[0]
        callback null, pages
      else "no data"



  #TODO finish dynamic loading of main feed
  everyone.now.loadMainNotify = (page, number, filter, callback) ->
    # @user.name is "n00b"
    #return;
    start = -(page+1) * number

    db.pageModel.findOne
      pageName: "main"
    ,
      notify:
        $slice: [start, number]
    , (err, result) ->
      unless err
        callback result.notify
      else
        console.log err


  everyone.now.loadMainPage = (page, number, filter, callback) ->
    
    console.log('loading main')
    @user.name is "n00b"
    startN = page * number
    #return;
    dbFilter = filter
    dbFilter = "likesN"  if filter is "likes"
    dbFilter = "edited"  if filter is "updated"

    db.pageModel.find(
      privacy:
        $ne: 3
    ,
      pageName: 1
      likes: 1
      likesN: 1
      privacy: 1
      contributors: 1
      owner: 1
      vLikes: 1
      backgroundImage: 1
      "images.url": 1
      "images.oHeight": 1
      "images.oWidth": 1
      background: 1
      created: 1
      edited: 1
      "versions.currentVersion": 1
    ).sort( "-"+dbFilter+" "+"pageName").skip(startN).limit(number).exec (err, result2) ->
      unless err
        responce = {}
        responce = result2
        # responce.type = "main"
        callback responce
      else callback err


  everyone.now.loadAll = (pageName, userProfile, version, callback) ->
  
    # callback ('bla')
    # return;
    #var pagesGroup = {};
    groupName = pageName
    groupName = "profile___" + userProfile  if pageName is "profile"
    
    @user.name is "n00b"
    
    #groupName='invite';
    #pageName='invite';
    # console.log groupName
    # console.log @user.name
    console.log 'permissions'
    console.log @user.pagePermissions[pageName]
    if @user.pagePermissions[groupName] is `undefined` or (@user.pagePermissions[groupName] is 3 and @user.pagePermissions[groupName] isnt "owner")
      
      #console.log(this.user.pagePermissions[pageName])
      callback "This page is private"
      return

    # if pageName == 'profile' && userProfile != undefined
    #   db.userModel.findOne
    #     username: userProfile
    #   ,
    #     password: 0
    #     salt: 0
    #   , (error, result) -> 
    #     unless error
    #       callback result
    #   return  
    
    unless version is `undefined`
      sliceParam = [parseInt(version), 1]
    else
      sliceParam = -1
    oldthis = this
    
    #var pageReg = new RegExp("^"+pageName+"$",'i')
    db.pageModel.findOne
      pageName: pageName
    ,
      versions:
        $slice: sliceParam

      text:
        $slice: -20

      notify: 0
        # $slice: -100
    , (error, result) ->
      if error
        callback error, null
      else
        
        #pageName=result.pageName;  
        nowjs.getGroup(groupName).addUser oldthis.user.clientId
        nowjs.getGroup("eyebeam-real-time").addUser oldthis.user.clientId  if oldthis.user.name is "eyebeam"
        
        #TODO: not n00b?
        if result.privacy < 3
          db.onlineModel.update
            nowId: oldthis.user.clientId
          ,
            $set:
              page: groupName
              user: oldthis.user.name
          ,
            upsert: true
          , (err) ->
            console.log err  if err

        nowjs.getGroup(groupName).pageUsers = {}  if nowjs.getGroup(groupName).pageUsers is `undefined`
        
        #leavePage
        if oldthis.user.currentPage isnt `undefined` and oldthis.user.currentPage isnt groupName
          if oldthis.user.currentPage?
            nowjs.getGroup(oldthis.user.currentPage).exclude(oldthis.user.clientId).now.updatePageUser "delete", oldthis.user.name
            delete nowjs.getGroup(oldthis.user.currentPage).pageUsers[oldthis.user.clientId]

            nowjs.getGroup(oldthis.user.currentPage).removeUser oldthis.user.clientId
            nowjs.getGroup("main").exclude(oldthis.user.clientId).now.updateFeed oldthis.user.name, oldthis.user.image, oldthis.user.currentPage, "leave"
            oldthis.user.currentPage = null
        oldthis.user.currentPage = groupName
        nowjs.getGroup("main").now.updateFeed oldthis.user.name, oldthis.user.image, groupName, "join"  if result.privacy < 3
        oldthis.now.updatePageUser "add", nowjs.getGroup(groupName).pageUsers, userProfile
        if oldthis.user.name is "n00b"
          userObj = {}
          userObj = n00b: true
          nowjs.getGroup(groupName).pageUsers[oldthis.user.clientId] = userObj
          nowjs.getGroup(groupName).now.updatePageUser "add", [userObj]
        else
          userObj = {}
          userObj[oldthis.user.name] = true
          nowjs.getGroup(groupName).pageUsers[oldthis.user.clientId] = userObj
          nowjs.getGroup(groupName).now.updatePageUser "add", [userObj]
        callback null, result


  everyone.now.camera = (transform, animate) ->
    nowjs.getGroup("eyebeam-real-time").now.updateMainDivServer transform, animate  if @user.name is "eyebeam-user"

  db.onlineModel.remove {}, (err) ->



  everyone.now.getAllUsers = (callback) ->
    db.onlineModel.find {},
      user: 1
      page: 1
      _id: 0
    , (err, res) ->
      callback res  unless err


  everyone.now.leftWindow = (left) ->
    if @user.currentPage?
      if left
        nowjs.getGroup(@user.currentPage).now.clientLeftWindow @user.name, true
        nowjs.getGroup(@user.currentPage).pageUsers[@user.clientId][@user.name] = false
      else
        nowjs.getGroup(@user.currentPage).now.clientLeftWindow @user.name, false
        nowjs.getGroup(@user.currentPage).pageUsers[@user.clientId][@user.name] = false

  everyone.on "leave", ->
    @user.clicks = 0  if @user.clicks is `undefined`
    
    #
    #   db.userModel.update({username:this.user.name},{$inc:{clicks:this.user.clicks}},function(err){
    #     if(err) console.log(err)
    #   })
    #
    db.userModel.update
      username: @user.name
    ,
      $set:
        nowId: null

      $inc:
        clicks: @user.clicks
    , (err) ->
      console.log err  if err

    nowjs.getGroup("main").exclude(@user.clientId).now.updateFeed @user.name, @user.name, @user.currentPage, "leave"  unless @user.currentPage is `undefined`
    delete nowjs.getGroup(@user.currentPage).pageUsers[@user.clientId]  unless nowjs.getGroup(@user.currentPage).pageUsers is `undefined`
    nowjs.getGroup(@user.currentPage).now.updatePageUser "delete", @user.name
    
    #pagesGroup[this.user.currentPage].removeUser(this.user.clientId);
    db.onlineModel.remove
      nowId: @user.clientId
    , (err) ->


  everyone.now.click = ->
    @user.clicks = 0  if @user.clicks is `undefined`
    @user.clicks += 1
    nowjs.getGroup("profile___" + @user.name).now.updateClicks()



  everyone.now.getAllPages = (callback)->
    db.pageModel.find (err, result)->
      callback(result)

  everyone.now.updateImageWH = (data)->
    console.log(data._id)
    db.pageModel.update
      "images._id" : data._id
    , '$set': 
        "images.$" : data
    , false, 
      true,
      (err) ->
        console.log err if err

