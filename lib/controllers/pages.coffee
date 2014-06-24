mongoose = require('mongoose')
pageModel = mongoose.model('pageModel')
notifyModel = mongoose.model('notifyModel')
userModel = mongoose.model('userModel')


module.exports = (everyone, nowjs) ->

  notifyUsers = require('./notify')(everyone,nowjs)





  #//////////////////
  #/ADD_DELETE PAGES
  #////////////////
  everyone.now.addPage = (pageName, copyPageName, callback) ->
    
    oldthis = this
    
    name = @user.name
    if @user.name is "n00b"
      callback "please log in to create page"
      return
    pageInit = {}
    if copyPageName != null && copyPageName != undefined
      pageModel.findOne
        pageName: copyPageName
      ,
        _id: 0
        likesN: 0
        likes: 0
      , (err, result) ->
        unless err
          pageInit = result._doc
          pageInit.pageName = pageName
          pageInit.owner = oldthis.user.name
          pageInit.privacy = 0
          pageInit.text = []
          pageInit.versions = []
          pageInit.children = []
          pageInit.parent = result.pageName
          pageInit.likes = []
          pageInit.created = new Date()
          pageInit.edited = new Date()
          # delete pageInit._id;
          newPage = new pageModel(pageInit)
          newPage.save (error, result) ->
            unless error
              notifyUsers [], result.owner, oldthis.user.userId, oldthis.user.image, "new", result._id
              callback null, pageName
            else
              callback error


    else
      checkPage = new RegExp("^" + pageName + "$", "i")
      pageModel.findOne
        pageName: checkPage
      ,
        _id: 0
      , (err1, result1) ->
        if  !err1 && !result1
          pageInit.pageName = pageName
          name = oldthis.user.name
          pageInit.owner = name
          pageInit.privacy = 0
          newPage = new pageModel(pageInit)
          
          #console.log(newPage)
          newPage.save (error, result) ->
            unless error
              notifyUsers [], result.owner, oldthis.user.userId, oldthis.user.image, "new", result._id
              #TODO look into this more
              everyone.now.updateMain(result, 'add')
              callback null, pageName
            else
              callback error, null

        else callback "name already taken, try a different one", null  unless !result1


  everyone.now.deletePage = (pageId, callback) ->
    unless @user.pagePermissions[pageId] is "owner"
      callback "you don't have permission do delete this page"
      return
    pageModel.remove
      _id: pageId
    , (error) ->
      unless error
        callback null

        everyone.now.updateMain pageName, 'delete'
        
        notifyModel.find
          pageObj: pageId
        .remove().exec()

      else
        callback error



  #/////////////////////////
  #/////////VERSIONS
  #///////////////////////

  #TODO save local change instead of db query?
  everyone.now.saveVersion = (callback) ->
    oldthis = this
    pageName = @user.currentPage
    return  if @user.pagePermissions[pageName] isnt "owner" and @user.pagePermissions[pageName] isnt 0
    pageModel.findOne
      pageName: pageName
    ,
      versions: 0
      children: 0
      _id: 0
      parent: 0
      privacy: 0
      lastId: 0
      text: 0
      likesN: 0
      likes: 0
    , (error, result) ->
      unless error
        newVersion = {}
        newVersion = result
        savedVersion = result.currentVersion
        
        #delete result.currentVersion;
        version = new versionModel(newVersion)
        
        #version.images=[];
        #console.log(version);
        pageModel.update
          pageName: pageName
        ,
          $push:
            versions: version

          $inc:
            currentVersion: 1
        , (err) ->
          
          #console.log(savedVersion)
          unless err
            callback null, savedVersion
            nowjs.getGroup(pageName).now.updateVersion savedVersion
            notifyUsers result.images, result.owner, oldthis.user.userId, oldthis.user.image, "version", pageName, savedVersion

      else
        console.log error


  everyone.now.deletePageVersion = (id, callback) ->
    oldthis = this
    pageName = @user.currentPage
    return  unless @user.pagePermissions[pageName] is "owner"
    
    #pageModel.update({pageName:pageName},{$pull : {"versions._id":id}, $inc:{currentVersion:-1}},function(error){
    pageModel.findOne
      pageName: pageName
    , (error, result) ->
      unless error
        
        #console.log(result)
        dVersion = result.versions.id(id).currentVersion
        console.log dVersion
        result.versions.id(id).remove()
        result.versions.id(id).remove()  unless result.versions.id(id) is `undefined`
        console.log result
        result.currentVersion--
        result.currentVersion = 0  if result.currentVersion < 0
        result.save (error) ->
          unless error
            nowjs.getGroup(pageName).exclude(oldthis.user.clientId).now.updateVersion dVersion, true
            callback null
          else
            callback error
            console.log error

      else
        callback error


  #/////////
  #/PRIVACY
  #///////

  everyone.now.setPrivacy = (pageName, privacy, editors, callback) ->
    # if _2d
    #   d2d = true
    # else
    #   d2d = false
    return  unless @user.pagePermissions[pageName] is "owner"
    db.pageModel.update
      pageName: pageName
    ,
      $set:
        privacy: privacy
        editors: editors
        # d2d: d2d
    , (err) ->
      unless err
        callback null
        # TODO do this a better way?
        nowjs.getGroup(pageName).now.pagePrivacy privacy


