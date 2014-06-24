mongoose = require('mongoose')
db={}
db.userModel = mongoose.model('userModel')
db.pageModel = mongoose.model('pageModel')


module.exports = (everyone) ->

  #/////////////
  #/PERMISSIONS
  #///////////
  # console.log(everyone)

  # everyone.now.getPagePermissions = (pageName, userProfile, version, callback) ->
  #   oldthis = this
  #   @user.pagePermissions = {}  if @user.pagePermissions is `undefined`
  #   @user.name is "n00b"
    
  #   #groupName='invite';
  #   #pageName='invite';
    
  #   #
  #   # if(version==null || version==undefined)
  #   #   version=-1;
  #   #
  #   db.pageModel.findOne
  #     pageName: pageName
  #   ,
  #     privacy: true
  #     owner: true
  #     editors: true
  #     currentVersion: 1
  #   , (err, result) ->
  #     if not err and result isnt `undefined`
  #       if result.currentVersion isnt undefined and version? and version isnt ""
  #         if result.currentVersion <= version
  #           callback result.currentVersion+version
  #           console.log(version)
  #           return
  #       owner = false
  #       if result.owner is oldthis.user.name
  #         oldthis.user.pagePermissions[result._id] = "owner"
  #         owner = true
  #       else
  #         oldthis.user.pagePermissions[result._id] = result.privacy
  #       unless result.editors is `undefined`
  #         i = 0

  #         while i < result.editors.length
  #           oldthis.user.pagePermissions[result._id] = 0  if result.editors[i] is oldthis.user.name and not owner
  #           i++
  #       oldthis.user.pagePermissions[result._id] = 2  if oldthis.user.name is "n00b" and result.privacy < 2
  #       if pageName is "profile"
  #         pageName = "profile___" + userProfile
  #         if userProfile is oldthis.user.name
  #           oldthis.user.pagePermissions[result._id] = "owner"
  #         else if oldthis.user.name is "n00b"
  #           oldthis.user.pagePermissions[result._id] = 2
  #         else
  #           oldthis.user.pagePermissions[result._id] = 2
  #       if pageName is "invite"
  #         oldthis.user.pagePermissions[result._id] = 0
  #         oldthis.user.pagePermissions[result._id] = "owner"  if oldthis.user.name is "balasan"
  #       oldthis.user.pagePermissions[result._id] = "owner"  if oldthis.user.name is "gifpumper"
  #       oldthis.now.setPagePermissions oldthis.user.pagePermissions[result._id], owner
  #       callback null, oldthis.user.name, oldthis.user.pagePermissions[result._id]
  #     else
  #       console.log err
  #       callback "noPage"


  everyone.now.logStuff = (msg) ->
    console.log msg



  #/////////
  #ADD USER
  #///////
  randomString = ->
    chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXTZabcdefghiklmnopqrstuvwxyz"
    string_length = 13
    randomstring = ""
    i = 0

    while i < string_length
      rnum = Math.floor(Math.random() * chars.length)
      randomstring += chars.substring(rnum, rnum + 1)
      i++
    randomstring

  #TODO: get rid of this or change to ADD USER
  everyone.now.updateUsers = (users, callback) ->
    for i of users
      user = new RegExp("^" + users[i].username + "$", "i")
      userModel.find
        username: user
      ,
        username: 1
      , (error, result) ->
        if result[0] is `undefined`
          console.log result
          users[i].salt = randomString()
          users[i].password = hash(users[i].password, users[i].salt)
          user = {}
          user[i] = new userModel(users[i])
          user[i].save (err) ->
            if err
              callback "there was an error, most likely the username you chose has already been taken"
              console.log err
            else
              callback null

        else
          callback "there was an error, most likely the username you chose has already been taken"
