mongoose = require('mongoose')
notifyModel = mongoose.model('notifyModel')
pageModel = mongoose.model('pageModel')
userModel = mongoose.model('userModel')
lastNotify = {}

module.exports = (everyone, nowjs)->

  # getMainFeed = (req, res)->
  #   offset = req.params.offset
  #   limit = req.params.limit

  everyone.now.loadMainNotify = (page, number, filter, callback) ->
    # @user.name is "n00b"
    #return;
    start = page * number


    console.log(@user.userId)

    userModel.findOne
      _id : @user.userId
      # username: "Pepper"
    ,
      favoriteUsers : 1
    , (err, user) ->
      # console.log user
      if !err && user
        notifyModel.find
          action :
            $ne : 'version'
          userObj : 
            $in : user.favoriteUsers
          # $slice: [start, number]
        .sort
          'likesN': 1
          'time':-1
        .skip(start)
        .limit(number)
        .populate
          path: 'pageObj'
          select: "likesN images backgroundImage coverImage created owner likes pageName"
          match:
            privacy:
              $lte:2
        .populate('userObj', "userImage username")
        .exec (err, result) ->
          unless err
            callback result
          else
            console.log err






  notifyUsers = (images, _owner, userId, image, action, pageId, version) ->
    notify = new notifyModel()
    notify.userObj = userId
    notify.action = action
    notify.pageObj = pageId
    notify.img = image
    notify.version = version  unless !version

    if action isnt "msg"
      
      notifyModel.findOne
        userObj: userId 
        pageObj: pageId 
        action: action
        version: version
      , (err, res) ->
        if res
          # res.time = new Date()
          # res.save(err) ->
          #   if err then console.log(err)
        else
          newNotify = new notifyModel(notify)
          newNotify.save (err)->
            if err then console.log(err) 
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



  # everyone.now.separateNotify = (callback)->
  #   console.log "running db ops"

  #   setPageId = (note, callback)->
  #     pageModel.findOne 
  #       pageName: note.page
  #     ,
  #       _id : 1
  #       pageName: 1
  #     , (err, page) ->
  #       if !err 
  #         if !page
  #           console.log "missing page " + note.page
  #         else
  #           note.pageObj = page._id
  #           callback(note)

  #   setUserId = (note, callback)->
  #     userModel.findOne 
  #         username: note.user
  #       ,
  #         _id : 1
  #       , (err, user) ->
  #         if !err 
  #           if !user
  #             console.log "missing user" + note.user
  #           else
  #             note.userObj = user._id
  #           callback(note)      


  #   notifyModel.find({}).remove ()->
  #     pageModel.findOne
  #       pageName: 'main'
  #     ,
  #       notify: 1
  #     , (err, res)->
  #         if !err 
  #           # console.log res
  #           callback (res.notify)
  #           for note in res.notify
  #             callback(note)
  #             setPageId note, (note)->
  #               setUserId note, (note)->
  #                 newNote = new notifyModel(note)
  #                 newNote.save (err)->
  #                   # callback(newNote)
  #                   if err
  #                     console.log(err)




  # everyone.now.cleanNotify = (callback)->
  #   notifyModel.find {}
  #   .sort
  #     'page':1
  #     'user':1
  #     'action':1
  #     'version':1
  #   .exec (err,res) ->
  #     prev
  #     for note in res
  #       if prev
  #         callback(note.page + ' ' +note.user + ' ' + note.action + ' ' + note.version)
  #         if note.version == prev.version && note.page == prev.page && note.action == prev.action && note.user==prev.user 
  #           note.remove()
  #           callback('removing ' + note)
  #       prev = note




