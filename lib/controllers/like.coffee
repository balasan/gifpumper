mongoose = require('mongoose')
pageModel = mongoose.model('pageModel')

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


  everyone.now.likePage = (action, version, callback) ->
    oldthis = this
    if @user.name is "n00b"
      callback "you must be registered to do this!"
      return
    pageName = @user.currentPage
    if action is "like"
      if version is `undefined`
        ver = 0
      else
        ver = {}
        ver["$slice"] = [version, 1]
      if version is `undefined`
        pageModel.findOne
          pageName: pageName
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
              pageName: pageName
            ,
              $addToSet:
                likes: oldthis.user.name

              $inc:
                likesN: 1
            , (err) ->
              console.log err  if err

            callback null
            notifyUsers result.images, result.owner, oldthis.user.name, oldthis.user.image, "like", pageName
            everyone.now.updateMain()
          else
            callback err

      unless version is `undefined`
        query = {}
        query["versions." + version + ".likes"] = $nin: [@user.name]
        query["pageName"] = pageName
        pageModel.findOne query,
          likes: 1
          likesN: 1
          owner: 1
          versions: ver
          privacy: 1
        , (err, result) ->
          if not err and result?
            pageModel.update
              pageName: pageName
              "versions.currentVersion": version
            ,
              $addToSet:
                "versions.$.likes": oldthis.user.name

              $inc:
                likesN: 1
                "versions.$.likesN": 1
            , (err) ->
              console.log err  if err

            callback null
            notifyUsers result.versions[0].images, result.owner, oldthis.user.name, oldthis.user.image, "like", pageName, version
            everyone.now.updateMain()
          else
            callback err

    else if action is "unlike"
      unless version is `undefined`
        pullObj = {}
        pullObj["versions." + version + ".likes"] = @user.name
        pullObj2 = {}
        pullObj2["versions." + version + ".likesN"] = -1
        pageModel.update
          pageName: pageName
          "versions.currentVersion": version
        ,
          $pull:
            "versions.$.likes": @user.name

          $inc:
            "versions.$.likesN": -1
            likesN: -1
        , (err) ->
          unless err
            callback null
          else
            callback err




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
