mongoose = require('mongoose')
pageModel = mongoose.model('pageModel')
userModel = mongoose.model('userModel')

module.exports = (everyone, nowjs) ->

  notifyUsers = require('./notify')(everyone,nowjs)

  #//////////
  #/LIKE
  #//////

  #console.log(pullObj2);

  #everyone.now.updateMain()

  #
  #        else pageModel.update({pageName:'main'},{$pop:{notify : -1}},function(err2){
  #          if(err2) console.log(err);
  #          })
  #  

  #console.log(lastNotify)

  #console.log(notify)
  #console.log('!!!! ' + newPageName)

  trim1 = (str) ->
    str.replace(/^\s\s*/, "").replace /\s\s*$/, ""


  everyone.now.likeToFollow = (callback)->

    populateFavorites = (user,page,callback)->

      # if user.favoritePages.indexOf(page._id) < 0
      #   user.favoritePages.push(page._id)

      userModel.findOne
        username : page.owner
      ,
        _id : 1
      , (err, owner) ->
        if user.favoriteUsers.indexOf(owner._id) < 0
          user.favoriteUsers.push(owner._id)
        user.save (err)->
        callback(user.username + " " + user.favoriteUsers.length)
      # user.save (err)->
      #   callback(user)        


    getFavorites= (user,callback)->
      pageModel.find
        likes : 
          $all : user.username
      ,
        pageName : 1
        owner: 1
      , (err, pages) ->
        callback(user,pages)




    userModel.find {}
    , (err, users) ->
      # callback(users)
      for user in users
        user.favoriteUsers=[]
        getFavorites user, (user, pages)=>
          for page in pages
            populateFavorites user, page, callback
            # callback(page)
          # user.save()
        # callback(user.username + " " + user.favoritePages.length + " " + user.favoriteUsers.length)




  everyone.now.likePage = (action, version, callback) ->
    oldthis = this
    if @user.name is "n00b"
      callback "you must be registered to do this!"
      return
    pageId = @user.currentPage
    if action is "like"
      if version is null
        ver = 0
      else
        ver = {}
        ver["$slice"] = [
          version
          1
        ]
      if version is null
        pageModel.findOne
          _id: pageId
          likes:
            $nin: [@user.name]
        ,
          privacy: 1
          likes: 1
          likesN: 1
          owner: 1
          "images.user": 1
        , (err, result) ->
          if not err and result?
            pageModel.update
              _id: pageId
            ,
              $addToSet:
                likes: oldthis.user.name

              $inc:
                likesN: 1
            , (err) ->
              console.log err  if err
              return


            callback null, action
            notifyUsers result.images, result.owner, oldthis.user.userId, oldthis.user.image, "like", pageId
            everyone.now.updateMain()
          else
            callback err
          return

      unless version is null
        query = {}
        query["versions." + version + ".likes"] = $nin: [@user.name]
        query["_id"] = pageId
        pageModel.findOne query,
          likes: 1
          likesN: 1
          owner: 1
          versions: ver
          privacy: 1
        , (err, result) ->
          if not err and result?
            pageModel.update
              _id: pageId
              "versions.currentVersion": version
            ,
              $addToSet:
                "versions.$.likes": oldthis.user.name

              $inc:
                likesN: 1
                "versions.$.likesN": 1
            , (err) ->
              console.log err  if err
              return

            callback null, action
            notifyUsers result.versions[0].images, result.owner, oldthis.user.userId, oldthis.user.image, "like", pageId, version
            everyone.now.updateMain()
          else
            callback err
          return

    else if action is "unlike"
      if version is null
        pageModel.update
          _id: pageId
        ,
          $pull:
            likes: @user.name

          $inc:
            likesN: -1
        , (err) ->
          unless err
            callback null, action
          else
            callback err
          return

      else
        pullObj = {}
        pullObj["versions." + version + ".likes"] = @user.name
        pullObj2 = {}
        pullObj2["versions." + version + ".likesN"] = -1
        
        #console.log(pullObj2);
        pageModel.update
          _id: pageId
          "versions.currentVersion": version
        ,
          $pull:
            "versions.$.likes": @user.name

          $inc:
            "versions.$.likesN": -1
            likesN: -1
        , (err) ->
          unless err
            
            #everyone.now.updateMain()
            callback null, action
          else
            callback err
          return

    return




  everyone.now.trimAll = ->
    pageModel.find {},
      pageName: 1
    , (err, result) ->
      unless err
        i = 0

        while i < result.length
          console.log result[i].pageName
          newPageName = trim1(result[i].pageName)
          if newPageName is ""
            newPageName = "_"
            console.log "_"
          unless result[i].pageName is newPageName
            pageModel.update
              pageName: result[i].pageName
            ,
              $set:
                pageName: newPageName
            , (err) ->
              console.log err  if err

            console.log "!!!! " + newPageName
          i++
