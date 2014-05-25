mongoose = require('mongoose')
notifyModel = mongoose.model('notifyModel')
pageModel = mongoose.model('pageModel')
userModel = mongoose.model('userModel')
lastNotify = {}

module.exports = (everyone, nowjs)->
  notifyUsers = (images, _owner, user, image, action, pageName, version) ->
    notify = new notifyModel()
    notify.user = user
    notify.action = action
    notify.page = pageName
    notify.img = image
    notify.version = version  unless !version 
    if action isnt "msg" and (lastNotify isnt {} or lastNotify.user isnt notify.user or lastNotify.page isnt notify.page or lastNotify.action isnt notify.action or lastNotify.version isnt notify.version)
      pageModel.update
        pageName: "main"
      ,
        $push:
          notify: notify
      , (err) ->
        console.log err  if err
      # if everyone.now.notifyFeed 
      everyone.now.notifyFeed [notify], null, true
    lastNotify = notify
    contributors = {}
    
    i = 0
    while i < images.length
      owner = undefined
      if i is images.length
        owner = _owner
      else
        owner = images[i].user
      if user is owner
        i=images.length
      if !owner or !contributors[owner] 
        i=images.length
      else
        contributors[owner] = 1
      userModel.findOne
        username: owner
      ,
        notify: 1
        nowId: 1
        newNotify: 1
      , (err, result2) ->
        unless err
          nowId = result2.nowId
          result2.notify = []  if !result2.notify 
          result2.notify.push notify
          if nowId
            nowjs.getClient nowId, ->
              @now.notifyUser [notify]  unless !@user

          else
            result2.newNotify++
          result2.save (err) ->
            console.log err  if err
      i++

